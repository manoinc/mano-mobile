# Backend contract

`mano-gateway` (Rust, juniper) at `POST :8082/graphql`. Fields are camelCase and
enums are SCREAMING_CASE. The source of truth is
`mano-gateway/src/schema/*.rs`; there is no SDL file.

For a phone to reach it, run the gateway with `BIND_ADDR=0.0.0.0:8082` and set
`adb reverse tcp:8082 tcp:8082`.

## What each port uses

| Port | Gateway operations | Gateway status | Mobile adapter |
|---|---|---|---|
| `ServiceCatalog` | `jobServices(category, searchText, page)`, `jobService(id)`, `jobServiceOffer(id)`, `offersByJobService(jobServiceId)` | **live, public** | `GatewayServiceCatalog` |
| `OfferManagement` | `createJobServiceOffer`, `updateJobServiceOffer`, `pauseJobServiceOffer`, `deleteJobServiceOffer` | live, auth required; **no list-mine, no resume** | `MockOfferManagement` |
| `ServiceRequestRepository` | `myServiceRequests`, `requestService`, `acceptServiceRequest`, `rejectServiceRequest` | stub; **no `cancelServiceRequest`** (taskmanager has it) | `MockServiceRequestRepository` |
| `JobRepository` | `myJobs`, `job`, `bookSlot`, `startJob`, `finishJob(actualHours)`, `cancelJob`, `rebook` | stub (taskmanager implements it, not wired) | `MockJobRepository` |
| `AvailabilityRepository` | `workerAvailability`, `myAvailabilityRules`, `upsertAvailabilityRule`, `removeAvailabilityRule`, `blockCalendar`, `unblockCalendar` | stub (scheduler implements it, not wired); **no calendar-feed operation** | `MockAvailabilityRepository` |
| `ConversationRepository`, `ChatRepository` | `myConversations`, `conversation`, `sendMessage`, `markConversationRead`, `messageAdded` | stub; **no chat backend**; the subscription never emits | `MockConversationRepository`, `MockChatRepository` |
| `ProviderOnboardingRepository` | `updateWorkerProfile`, `submitVerificationRequest` | stub; no backend | `MockProviderOnboardingRepository` |

## Mapping notes

- `AvailabilityRule` is weekdays + start minute + duration. The future gateway
  adapter translates it to and from the RFC 5545 `rrule` (durations are
  multiples of 30).
- `Message.fromMe` is derived by the adapter, by comparing the sender with the
  viewer.
- `ServiceRequest.serviceTitle` and `Job.serviceTitle` are resolved by the
  adapter from the offer's `jobServiceId`.
- The catalog returns only `offerantId` for an offer, with no provider name,
  photo or rating, so offer cards cannot show who the provider is yet.
- There is no list-categories query. `category` is an exact-match free-text
  filter, so the app keeps a static category list.

## Statuses

| Domain | Gateway |
|---|---|
| `ServiceRequestStatus` pending / accepted / rejected / cancelled | `PENDING` / `ACCEPTED` / `REJECTED` / `CANCELLED` |
| `JobStatus` scheduled / inProgress / finished / cancelled | `SCHEDULED` / `IN_PROGRESS` / `FINISHED` / `CANCELLED` |
| `OfferStatus` active / paused / deleted | `ACTIVE` / `PAUSED` / `DELETED` |
| `RateType` fixed / hourly | `FIXED` / `HOURLY` |
| `VerificationStatus` | `PENDING`, `UNDER_REVIEW`, `APPROVED`, `REJECTED`, `INFORMATION_REQUIRED` (+ `notSubmitted` locally) |

## Auth

**Keycloak is dropped.** Its sign-in opens a browser tab inside the app, which
breaks the native feel. The team is trialling **SuperTokens** instead: there is a
Flutter SDK for native sign-in screens, and the Rust (gateway) side is being
built by hand.

Until that lands:

- The gateway's verifier is still Keycloak's, so with no `KEYCLOAK_ISSUER_URL`
  every request is anonymous. Public catalog reads work; any mutation answers
  `authentication required`.
- `GatewayTransport.run(..., accessToken:)` is auth-vendor agnostic. A
  SuperTokens adapter only needs to supply the token, and lands as a
  `SessionRepository` in `mano_data` plus one override in `mano_session`.

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

The seed uses the app's category ids (`cleaning`, `plumbing`, `electrical`,
`painting`, `gardening`). It is idempotent: it truncates the catalog first.

## Gateway defects to raise

- On branch `stub-fixtures`, merge `daf57f7` dropped `mod fixtures;` from
  `src/schema/mod.rs`, so the 947-line fixture set no longer compiles in. Every
  non-catalog resolver returns `not implemented`.
- `README.md` contains unresolved conflict markers.
- `Viewer.role` checks for the roles `worker`/`staff`, but the old Keycloak realm
  defined `requester`/`provider`. Revisit when SuperTokens roles are defined.
- GraphiQL/Playground point at `/subscriptions`; the route is `/subscription`.
- Missing operations: list my offers, resume an offer, `cancelServiceRequest`,
  list categories, and calendar-feed issue/revoke plus the `.ics` route
  (gateway issue #3).
