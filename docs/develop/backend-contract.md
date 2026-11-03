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
| `ServiceRequestRepository` | `myServiceRequests`, `requestService`, `acceptServiceRequest`, `rejectServiceRequest`, `cancelServiceRequest` | **live** (D5 taskmanager over gRPC) | `GatewayServiceRequestRepository` (offline: `MockServiceRequestRepository`) |
| `JobRepository` | `myJobs`, `job`, `bookSlot`, `startJob`, `finishJob(actualHours)`, `cancelJob`, `rebook` | **live** (D5; `bookSlot` also needs D4) | `GatewayJobRepository` (offline: `MockJobRepository`) |
| `AvailabilityRepository` | `workerAvailability`, `myAvailabilityRules`, `upsertAvailabilityRule`, `removeAvailabilityRule`, `myCalendarBlocks`, `blockCalendar`, `unblockCalendar`, `myCalendarFeed`, `regenerateCalendarFeed`, `revokeCalendarFeed` + `.ics` route | **live** (D4 scheduler over gRPC) | `GatewayAvailabilityRepository` |
| `ConversationRepository`, `ChatRepository` | `myConversations`, `openConversation(reference: {withWorkerId \| jobId})`, `conversation`, `sendMessage`, `markConversationRead`, `messageAdded` | **live** (D7 chat over gRPC) | `GatewayConversationRepository`, `GatewayChatRepository` |
| `ProjectRepository` (requester) | `myProjects` with `quotes(page)`, `publishProject`, `cancelProject`, `selectQuote`, `discardQuote` | **live** (D9 mano-projects over gRPC); client role | `GatewayProjectRepository` |
| `LeadRepository` (provider) | `openProjects(category)`, `submitQuote`, `myQuotes` | **live** (D9); worker role. `purchaseProjectLead` is a D6 stub, so quotes are free | `GatewayLeadRepository` |
| `MediaUploader` | `requestChatMediaUpload`, `requestAvatarUpload`, `finalizeMediaUpload` + a PUT to Garage | **live** (mano-media, embedded); work-image and review-media uploads are stubs | `GatewayMediaUploader` (project and portfolio photos: `MockMediaUploader`). See [Media](media.md) |
| `ChatRepository` media | `Message.media`, `sendMessage(mediaIds)` | **live** | `GatewayChatRepository` |
| `ReviewRepository` | `reviewWorker`, `reviewClient`, `job { worker { averageRating ratingsCount reviews(page) } }` | **live** (D8 mano-reviews over gRPC) | `GatewayReviewRepository`. See [Reviews](reviews.md) |
| `ProviderDirectory` | none: there is no `workerProfile(id)` | missing | `MockProviderDirectory` |
| `ProviderOnboardingRepository` | `updateWorkerProfile`, `submitVerificationRequest` | stub (D2, D10 `not implemented`) | `MockProviderOnboardingRepository` |
| `ClientProfileRepository` | `updateClientProfile(displayName, photoUrl, phone, email)` | stub (D2 `not implemented`); no client-profile query | `MockClientProfileRepository`. See [REQ-08](../modules/REQ-08-perfil.md) |
| `AddressBook` | none | missing | `MockAddressBook` |
| `PaymentMethods` | none (no billing bridge; cards to be tokenised by Wompi) | missing | `MockPaymentMethods` (display data only) |
| `SupportDesk` (both apps) | `createSupportTicket(subject, description)` → `ticketNumber` | stub (D11) | `MockSupportDesk` |
| `ProviderProfileEditor` | `updateWorkerProfile` | stub, and has no bio, skills or portfolio | `MockProviderProfileRepository` (the same instance Perfil reads) |
| `SupportDesk` | `createSupportTicket(subject, description)` → `ticketNumber`, `status` FILED | stub; no PQRS kind | `MockSupportDesk` |
| `PayoutAccounts` | `registerPayoutAccount` (no read or remove) | stub; no billing bridge (mano-billing `RegisterPayoutAccount` is the real shape) | `MockPayoutAccounts` |
| `SessionRepository` | SuperTokens FDI: `/auth/signin`, `/auth/signup` (with `role`), `/auth/session/refresh`, `/auth/signout` | **live** in `mano-auth` (`:3001`); the gateway *verifies* tokens | `SuperTokensSessionRepository` when configured |

Every live D4/D5/D7 operation needs a signed-in caller; both apps now create
real accounts through `mano-auth` (see **Auth**).

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
- Chat: `Conversation.type` is really **`kind`** (`DIRECT` / `SUPPORT`).
  `Conversation.participant` is the participant whose `profileId` is not the
  viewer's (the session subject); `WORKER` maps to `ManoRole.provider`, `CLIENT`
  and `STAFF` to `ManoRole.requester`. `lastMessage` is `lastMessage.content` or
  `''`, `lastMessageAt` its `sentAt` in local time, or null with no messages
  (Bandeja then shows no time and "Sin mensajes aún", and sorts it last).
  Participant names are placeholders too, so rows and the chat header use
  `participantLabel` ("Cliente" / "Profesional" by role).
- `openConversation` is find-or-create; the app sends exactly one of
  `withWorkerId` or `jobId` and maps the result with the same
  `toConversation` as `myConversations` (`gateway_chat_json.dart`). "Escribir"
  on a job opens it by `jobId`. A pending request has no job, so the provider's
  request sheet still only goes to `/inbox`.
- Message `sentAt` is read in local time, like every other instant.
- `Message.fromMe` is `sender.profileId == viewer`. `status` is `read` once
  `readAt` is set, otherwise `delivered` (the gateway has no "sent" state).
- Messages come newest first (`messages(page: {first: 50})`; the
  `conversation(messagePage:)` argument is ignored); the adapter reverses them.
  A sent message also arrives on `messageAdded`; `ChatThreadNotifier` upserts
  by id, so it shows once.
- `ServiceRequest.serviceTitle`, `ServiceRequest.category` (and so its lead
  cost) and `Job.serviceTitle` are resolved by the adapter through the injected
  `ServiceCatalog`, from the offer's `jobServiceId`, once per service per
  adapter instance (`ServiceLookup`). A service the catalog doesn't know gives
  an empty title and category.
- Requests and jobs carry placeholder profiles: only `client { id }` and
  `worker { id }` are real, so every `Party` has an empty name and photo. A
  request's provider is the offer's `offerantId`. Screens read
  `clientName` / `providerName` (`mano_session`), which say "Cliente" or
  "Profesional" until the profile domain (D2) lands. Job details use
  `partyLine`: name over role, or the role alone ("Cliente", "Tu profesional")
  so a nameless party is not labelled twice.
- `Job.start` / `end` come from `appointment`; without one, `start` is
  `createdAt` and `end` is null. `rateType` and `amountCop` come from
  `pricing`. `actualHours` is always null: the gateway doesn't return it.
- Requests have no neighborhood or photos on the gateway: `neighborhood` is
  `''` and `photoUrls` is empty.
- Times are sent as UTC RFC 3339 and read back in local time. `bookSlot`'s
  `slotStart` must be exactly a published slot's start.
- Offline (`offlineMarketplaceProvider`), the two mocks stay coupled: accepting
  a request schedules a job and rebooking files a request. Live, the backend
  does that, so accepting refetches `myJobsProvider` and booking refetches
  `availableSlotsProvider`.
- Nothing is pushed for requests, jobs or projects, so the reads refetch on
  pull-to-refresh and when the app comes back into view
  (`refreshOnResumeProvider`, which invalidates `marketplaceReads`).
- The catalog returns only `offerantId` for an offer, with no provider name,
  photo or rating, so offer cards cannot show who the provider is yet.
- There is no list-categories query. `category` is an exact-match free-text
  filter, so the app keeps a static category list (see **Categories**).

## Projects and quotes

- Roles are enforced by the projects service, not the app. Refusals arrive as
  `PermissionDenied: …`, `NotFound: …` (also a stranger probing a project) or
  `FailedPrecondition: …` (state machine). `guardGateway` maps them to
  `DataRejected` / `DataNotFound`.
- `Project.quotes` is non-null **only for the owning client**; a worker's
  `openProjects` never carries quotes. The app's `Project.quotes` is null the
  same way.
- `Project.client` is hidden from workers until a lead is purchased, and
  `Quote.clientContact` is non-null only for the selected worker with a
  purchased lead. Neither is mapped yet.
- One quote per worker per project: a second `submitQuote` answers
  `AlreadyExists: …`, which surfaces as `DataRejected`; `failure.isAlreadyQuoted`
  (`mano_domain`) tells it apart so the screen can say "Ya cotizaste este
  proyecto".
- Rules mirrored on the entities: only `OPEN` takes quotes; select, discard and
  cancel work while `OPEN` or `AWARDED`. Selecting swaps out (discards) the
  earlier pick; discarding the selected quote reopens the project.
- Money is whole pesos: `Money.amount` is rounded to `int`, and budgets and
  amounts are sent as numbers. `photos` is always sent as `[]`: there is no
  upload yet.
- Pages ask for `first: 50`, with no cursor paging yet; `myProjects` asks
  `quotes(page: {first: 50})` per project.
- Nested quotes take their project id and title from the parent;
  `myQuotes`/`submitQuote`/`selectQuote` select `project { id title }`.
- `WorkerProfile` is a placeholder (empty `displayName`, null `photoUrl`), so a
  quote shows no provider name yet.

## Subscriptions (WebSocket)

`messageAdded(conversationId)` runs over `ws://host:8082/subscription`
(`ManoConfig.gatewaySubscriptionUrl`), through `SubscriptionClient`
(`mano_data`).

- Protocol is always **`graphql-transport-ws`**: `connection_init` /
  `connection_ack` / `subscribe` / `next` / `error` / `complete` / `ping` /
  `pong`.
- **Auth is in the `connection_init` payload**, `{"authorization": "Bearer
  <token>"}`; the gateway ignores headers on the upgrade. An invalid token is
  refused during init; with none, init succeeds and resolvers answer
  "authentication required".
- One socket shared by every subscription, opened on the first and closed after
  the last. A dropped socket reconnects with capped backoff (0.5 s doubling to
  30 s), a fresh token from `freshAccessToken()` and every live subscription
  re-sent.
- `messageAdded` sends only new messages, never read receipts, so my messages
  stay `delivered` until the thread reloads. A non-participant gets one error,
  then the stream completes.

## Statuses

| Domain | Gateway |
|---|---|
| `ServiceRequestStatus` pending / accepted / rejected / cancelled | `PENDING` / `ACCEPTED` / `REJECTED` / `CANCELLED` |
| `JobStatus` scheduled / inProgress / finished / cancelled | `SCHEDULED` / `IN_PROGRESS` / `FINISHED` / `CANCELLED` |
| `OfferStatus` active / paused / deleted | `ACTIVE` / `PAUSED` / `DELETED` |
| `ProjectStatus` open / awarded / closed / cancelled | `OPEN` / `AWARDED` / `CLOSED` / `CANCELLED` |
| `QuoteStatus` submitted / selected / discarded | `SUBMITTED` / `SELECTED` / `DISCARDED` |
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

**Served by `mano-auth`** (TypeScript, SuperTokens backend SDK, `:3001`).
The old gap — nothing serving the FDI routes — is closed. Every call sends
`rid: emailpassword` and `st-auth-mode: header`.

- **Sign-up sends the role.** `SessionRepository.signUp(credentials, role:)`
  posts `formFields` `[email, password, {id: role, value: requester|provider}]`.
  `SessionManager.signUp` takes the role from `ManoConfig.appRole`, so the
  requester app makes Solicitantes and the provider app Proveedores.
- **Sign-in takes no role.** The role comes back in the token's `st-role`
  claim. A requester account may sign in to the provider app; nothing blocks
  it yet.
- **Failure mapping** (`SuperTokensSessionRepository`):

| mano-auth answer | `AuthFailure` | Copy (`authFailureCopy`, `mano_session`) |
|---|---|---|
| 200 `WRONG_CREDENTIALS_ERROR` (sign-in) | `WrongCredentials` | Correo o contraseña incorrectos |
| 200 `FIELD_ERROR` on `email` (sign-up: "already exists") | `EmailAlreadyRegistered` | Ese correo ya tiene cuenta. Inicia sesión. |
| 200 `FIELD_ERROR` on any other field (`password`, `role`) | `SignInRejected(reason)` | No pudimos aceptar esos datos. Revísalos. |
| any non-200, or the server unreachable | `AuthUnavailable` | No pudimos conectarnos. Intenta de nuevo. |

- The apps check the email shape and the password (8+ characters, a letter
  and a number, SuperTokens' default rules) before sending, so a password
  `FIELD_ERROR` should be rare.
- **Where accounts are made.** Requester: name → email → password (signs up)
  → address → notifications, ending signed in. Provider: welcome → email →
  password (signs up) → the profile questions → pending. "Ahora no" on either
  flow still browses as a guest; guests are asked to sign in at account-only
  actions (`ManoAccountNeededSheet`).
- **Greetings** ("Hola, Ana") use the first name typed while signing up: the
  requester's given name, the provider's display name (first word), then the
  provider profile's first name. The account's name is used only when it is
  not an email address, which today it always is; otherwise the header says
  plain "Hola" (`mano_session/lib/src/home/greeting_name.dart`).

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

# 4. let the phone reach it (3900 is Garage, for photo uploads and downloads)
adb reverse tcp:8082 tcp:8082
adb reverse tcp:3900 tcp:3900
```

For chat photos and reviews you need the whole stack: Garage, RabbitMQ and
mano-reviews. Follow `mano-gateway/docs/local-stack.md`.

The seed uses the canonical category ids (see **Categories**). It is
idempotent: it truncates the catalog first.

## Gateway defects to raise

- `Viewer.role` checks for the roles `worker`/`staff`, but the app's roles are
  `requester`/`provider`. Align them when SuperTokens roles are defined.
- GraphiQL/Playground point at `/subscriptions`; the route is `/subscription`.
- SuperTokens tokens carry no username or email, so `me { username email }` is
  `null` until the auth server adds them to the access-token payload.
- Missing operations: list categories. (List my offers, resume an offer,
  list my calendar blocks and `cancelServiceRequest` are now served.)
- Calendar feed: `myCalendarFeed` is a read-only
  `CalendarFeedStatus { active createdAt }` and never rotates the link
  (`active: false` maps to `null`). Tokens are stored hashed, so the URL exists
  only in `regenerateCalendarFeed { url createdAt }`, which rotates the link.
  The app keeps that URL in memory (`issuedCalendarFeedProvider`) to show and
  copy it once.
- Projects: the service's `CloseProject` and `MarkLeadPurchased` have no
  GraphQL field, so a requester cannot close a project and a lead can never be
  purchased (`purchaseProjectLead` is a D6 stub). Contact reveal is stitched
  with an empty phone.
- Chat participants carry `displayName: ""` and no photo, so the inbox and
  thread header have no name to show until profiles land. No subscription
  pushes read receipts or the inbox (`unreadCount`, `lastMessage`).
- `workerAvailability` doesn't subtract slots other clients already booked, so
  a client may be offered a taken slot; `bookSlot` then fails and the booking
  screen shows the failure.
- Profiles: there is no `workerProfile(id)` / `clientProfile(id)`, and
  `JobServiceOffer` has only `offerantId`. So a requester cannot open a
  stranger's profile and offer cards cannot show stars. Reviews' `author` is a
  bare participant (empty name, no photo). The requester's provider profile
  (REQ-07) is built on `MockProviderDirectory`; live, it shows "No encontramos
  a este profesional" and cards show "Nuevo" until these land.
- Reviews: no "already reviewed" field on `Job` (the app keeps a session set),
  and `ReviewInput` has no `mediaIds`.
- Media: `requestWorkImageUpload` and `requestReviewMediaUpload` are stubs, and
  there is no upload kind for project photos, so `ProjectInput.photos` takes
  plain URL strings. chatservice refuses an empty `content` even with
  `mediaIds`, so a photo always needs a caption (the app has to send one).
  `sendMessage` does not check that the media ids are
  finalized, owned and in that chat, although the media plan says it should.
- `docs/schema.graphql` is stale: it misses `requestChatMediaUpload`,
  `Message.media` and `sendMessage(mediaIds)`. Read the resolvers.
- Profile, support (`createSupportTicket`) and payout (`registerPayoutAccount`)
  mutations are all `not implemented` stubs, and the gateway has no billing bridge.
  Beyond that: `updateWorkerProfile` has no bio, skills or portfolio fields;
  `createSupportTicket` has no PQRS kind (petición, queja, reclamo,
  sugerencia); payouts have no read (`myPayoutAccount`) or remove; billing's
  `AccountHolder` wants an `email` the app cannot read from the token yet.
