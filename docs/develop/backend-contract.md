# Backend contract

`mano-gateway` (Rust, juniper) at `POST :8082/graphql`. Fields are camelCase and
enums are SCREAMING_CASE. The SDL is `mano-gateway/docs/schema.graphql`; the
resolvers in `src/schema/*.rs` are the source of truth.

Always read the gateway at **`origin/master`**. The old `stub-fixtures` branch
is stale; the local clone tracks `master` (`git -C ../mano-gateway pull --ff-only`).

For a phone to reach it, run the gateway with `BIND_ADDR=0.0.0.0:8082` and set
`adb reverse tcp:8082 tcp:8082`.

## What each port uses

| Port | Gateway operations | Gateway status (master) | Mobile adapter |
|---|---|---|---|
| `ServiceCatalog` | `jobServices(category, searchText, page)`, `jobService(id)`, `jobServiceOffer(id)`, `offersByJobService(jobServiceId)` | **live, public** | `GatewayServiceCatalog` |
| `OfferManagement` | `myJobServiceOffers(includeDeleted: false)`, `createJobServiceOffer`, `updateJobServiceOffer`, `pauseJobServiceOffer`, `resumeJobServiceOffer`, `deleteJobServiceOffer` (soft) | live, auth required | `GatewayOfferManagement` |
| `ServiceRequestRepository` | `myServiceRequests`, `requestService`, `acceptServiceRequest`, `rejectServiceRequest` | **live** (D5 taskmanager over gRPC); **no `cancelServiceRequest`** | `MockServiceRequestRepository` |
| `JobRepository` | `myJobs`, `job`, `bookSlot`, `startJob`, `finishJob(actualHours)`, `cancelJob`, `rebook` | **live** (D5; `bookSlot` also needs D4) | `MockJobRepository` |
| `AvailabilityRepository` | `workerAvailability`, `myAvailabilityRules`, `upsertAvailabilityRule`, `removeAvailabilityRule`, `myCalendarBlocks`, `blockCalendar`, `unblockCalendar`, `myCalendarFeed`, `regenerateCalendarFeed`, `revokeCalendarFeed` + `.ics` route | **live** (D4 scheduler over gRPC) | `GatewayAvailabilityRepository` |
| `ConversationRepository`, `ChatRepository` | `myConversations`, `conversation`, `sendMessage`, `markConversationRead`, `messageAdded` | **live** (D7 chat over gRPC) | `MockConversationRepository`, `MockChatRepository` |
| `ProviderOnboardingRepository` | `updateWorkerProfile`, `submitVerificationRequest` | stub (D2, D10 `not implemented`) | `MockProviderOnboardingRepository` |
| `SessionRepository` | SuperTokens FDI: `/auth/signin`, `/auth/signup`, `/auth/session/refresh`, `/auth/signout` | gateway only *verifies* tokens; **no FDI auth server yet** | `SuperTokensSessionRepository` when configured |

Every live D4/D5/D7 operation needs a signed-in caller, so wiring those ports
waits on the SuperTokens auth server below.

## Mapping notes

- `AvailabilityRule` is weekdays + start minute + duration; `rrule_codec.dart`
  translates it to and from the RFC 5545 `rrule`:
  `{1,3}, 8:00, 240 min` ⇄ `FREQ=WEEKLY;BYDAY=MO,WE;BYHOUR=8;BYMINUTE=0` with
  `durationMinutes: 240` (the length of each occurrence, a multiple of 30).
  Only `FREQ`, `BYDAY` (plain day codes), one `BYHOUR` and one `BYMINUTE` are
  read; a missing `BYHOUR`/`BYMINUTE` means midnight. Any other rule (daily,
  `INTERVAL`, several hours, ordinal days…) is skipped by `myRules`.
- `upsertAvailabilityRule` is sent with `validFrom` = today (local date),
  `timezone: America/Bogota`, and `id` when replacing a stored rule.
- `workerAvailability` takes whole dates, `to` exclusive. The adapter asks for
  every day the caller's range touches and drops slots starting outside it.
  Instants (`DateTime`) go out as UTC ISO 8601 and come back as local time.
- A `false` from `removeAvailabilityRule`, `unblockCalendar` or
  `revokeCalendarFeed` is `DataNotFound`.
- Offer JSON (`offerFields`, `offerFromJson`, `rateTypeToJson`) lives once in
  `mano_data/lib/src/gateway/offer_json.dart`; `amount` is sent as a number of
  whole pesos. `updateJobServiceOffer` gets only the fields that changed.
  `myOffers` excludes `DELETED` offers.
- `Message.fromMe` is derived by the adapter, by comparing the sender with the
  viewer.
- `ServiceRequest.serviceTitle` and `Job.serviceTitle` are resolved by the
  adapter from the offer's `jobServiceId`.
- The catalog returns only `offerantId` for an offer, with no provider name,
  photo or rating, so offer cards cannot show who the provider is yet.
- There is no list-categories query. `category` is an exact-match free-text
  filter, so the app keeps a static category list (see **Categories**).

## Statuses

| Domain | Gateway |
|---|---|
| `ServiceRequestStatus` pending / accepted / rejected / cancelled | `PENDING` / `ACCEPTED` / `REJECTED` / `CANCELLED` |
| `JobStatus` scheduled / inProgress / finished / cancelled | `SCHEDULED` / `IN_PROGRESS` / `FINISHED` / `CANCELLED` |
| `OfferStatus` active / paused / deleted | `ACTIVE` / `PAUSED` / `DELETED` |
| `RateType` fixed / hourly | `FIXED` / `HOURLY` |
| `VerificationStatus` | `PENDING`, `UNDER_REVIEW`, `APPROVED`, `REJECTED`, `INFORMATION_REQUIRED` (+ `notSubmitted` locally) |

## Categories

The gateway and `mano-jobServiceCRUD` store `category` as free text, and no
backend repo seeds it. The app's canonical ids live once, in
`ServiceCategories` (`mano_domain`):

| Id | Label |
|---|---|
| `cleaning` | Limpieza |
| `plumbing` | Plomería |
| `electrical` | Electricidad |
| `painting` | Pintura |
| `gardening` | Jardinería |

- `GatewayServiceCatalog` folds backend spellings onto these ids on read
  (`Plumbing`, `Plomería`, `JARDINERIA` → `plumbing`/`gardening`); unknown text
  passes through and is shown as-is.
- Search sends the canonical id, and the gateway filter is an exact match, so
  services must be **stored** with these ids. `tools/dev/seed_catalog.sql` does;
  backend tests currently use `"Plumbing"`. To agree with the backend team: store
  the lowercase ids, or add a list-categories query.
- Labels come from `ServiceCategories.labelOf`, in both apps.

## Auth

**Keycloak is dropped**: its sign-in opens a browser tab inside the app, which
breaks the native feel. Mano uses **SuperTokens**, email and password, with
native screens.

- The gateway (master) verifies SuperTokens access tokens against the core's
  JWKS when `SUPERTOKENS_CORE_URL` is set; with nothing set it runs anonymously.
- The app talks to a SuperTokens **API domain** (the FDI routes under `/auth`)
  through `SuperTokensSessionRepository` in `mano_data`. It uses header mode
  (`st-auth-mode: header`): tokens arrive in the `st-access-token`,
  `st-refresh-token` and `front-token` headers. The refresh token is kept in
  the keystore (`SecureTokenStore`); the access token lives in memory only.
- It is switched on per build:
  `flutter run --dart-define=SUPERTOKENS_API_DOMAIN=http://localhost:3001`.
  Without it, sign-in reports "not configured" and the app runs as before.
- Every gateway call asks `SessionManager.freshAccessToken()` (`mano_session`)
  for its bearer token. A token within a minute of expiry is renewed first,
  and concurrent calls share one renewal. Offline, the still-valid token is
  used. A refused renewal signs out with `SessionExpired`. There are no
  background timers.
- Session states are `SignedOut` (at the door), `Guest` (browsing without an
  account) and `SignedIn`. `hasAccountProvider` gates account-only actions.

**Gap:** nothing serves the FDI routes yet. The gateway only verifies tokens.
Someone has to stand up the SuperTokens backend SDK (or hand-build the four
routes) beside the core before sign-in works end to end. The adapter is
covered by tests against a fake HTTP client.

## Running the gateway locally

```bash
# 1. a throwaway Postgres, so the catalog persists and can be seeded
docker run -d --name mano-dev-postgres -e POSTGRES_PASSWORD=mano -e POSTGRES_DB=mano \
  -p 127.0.0.1:5433:5432 postgres:18-alpine

# 2. the gateway (it runs the catalog migrations on start)
cd ../mano-gateway && cargo build
DATABASE_URL=postgres://postgres:mano@127.0.0.1:5433/mano BIND_ADDR=0.0.0.0:8082 \
  ./target/debug/mano-gateway

# 3. seed the catalog; writes need an authenticated user, so seed straight into Postgres
docker exec -i mano-dev-postgres psql -q -U postgres -d mano < tools/dev/seed_catalog.sql

# 4. let the phone reach it
adb reverse tcp:8082 tcp:8082
```

The seed uses the canonical category ids (see **Categories**). It is
idempotent: it truncates the catalog first.

## Gateway defects to raise

- `Viewer.role` checks for the roles `worker`/`staff`, but the app's roles are
  `requester`/`provider`. Align them when SuperTokens roles are defined.
- GraphiQL/Playground point at `/subscriptions`; the route is `/subscription`.
- SuperTokens tokens carry no username or email, so `me { username email }` is
  `null` until the auth server adds them to the access-token payload.
- Missing operations: `cancelServiceRequest`, list categories. (List my
  offers, resume an offer and list my calendar blocks are now served.)
- **Open: `myCalendarFeed` rotates the link.** On master it calls the
  scheduler's `IssueCalendarFeed`, which revokes the live token and issues a
  new one, because tokens are stored hashed and cannot be handed back. Every
  read of the feed therefore kills the URL a calendar app is subscribed to.
  `GatewayAvailabilityRepository.myFeed` reads `myCalendarFeed` until the
  gateway offers a non-rotating read (for example: metadata only, URL shown on
  issue).
