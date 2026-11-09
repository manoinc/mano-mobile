# Profiles

Names, contact details, referral codes and verification come from
**mano-profiles** (gRPC), which the gateway stitches onto `viewer`. The photo
comes from mano-media, ratings from mano-reviews, and job counts from
mano-taskmanager.

## Gateway to domain

| Gateway | Domain | Port |
|---|---|---|
| `viewer.clientProfile { displayName phone email photoUrl }` | `ClientProfile` | `ClientProfileRepository` |
| `updateClientProfile(input: {displayName phone email})` | `ClientProfile` | `ClientProfileRepository.update` |
| `updateClientProfile(input: {photoMediaId})` | `ClientProfile.photoUrl` | `ClientProfileRepository.updatePhoto(MediaAttachment)` |
| `viewer.workerProfile { id displayName photoUrl phone email }` | `ProviderProfile.party`, `phone`, `email` | `ProviderProfileRepository.profile` |
| `workerProfile.workZone` ("Chapinero, Usaquén") | `ProviderProfile.zones` (split on commas) | same |
| `workerProfile.verification.isVerified` | `ProviderProfile.verified` | same |
| `workerProfile.averageRating`, `ratingsCount` | `ProviderStats.rating`, `reviewCount` | `ProviderProfileRepository.stats` |
| `workerProfile.jobsCompleted` | `ProviderStats.jobsCompleted` | same |
| `workerProfile.completionRate` (0..1) | `ProviderStats.completionRatePct` (rounded percent) | same |
| `workerProfile.reviews(page)` | `List<Review>` | `ProviderProfileRepository.reviews` |
| `workerProfile.referralCode` | `ReferralProgram.code` | `ProviderProfileRepository.referral` |
| `updateWorkerProfile(input: {displayName workZone})` | the saved name and zones | `ProviderProfileEditor.save` |
| `linkWorkerByReferralCode(code)` | the professional's name | `ReferralLinker` |

## Jobs done and completion rate

The gateway asks mano-taskmanager's `GetWorkerJobStats` for the worker's
finished and cancelled job counts (counts only, so any signed-in caller may
read them on any `WorkerProfile`).

- `jobsCompleted` = finished jobs.
- `completionRate` = finished / (finished + cancelled). A cancellation by
  **either** side counts against it, because a job does not record who
  cancelled. Null until the worker has closed a job.
- Both are null when the gateway has no `TASKMANAGER_URL`.

## Not served

| Field | In the app |
|---|---|
| `responseRatePct` | null live; the tile is hidden |
| referral reward (`ReferralProgram.reward`: invited, goal, coins) | null live; the card shows the code only, no coin or progress |
| `bio`, `yearsExperience`, `skills`, portfolio | kept in memory for the session (`localProviderDetailsProvider`), starting blank; hidden while blank |

A screen hides what is not served rather than showing a mock number next to
live ones.

## First read creates the profile

mano-profiles has no row for an account until its first write, and fills
placeholders ("Worker", "Unknown", "Profile") when a write omits a field. So
when `viewer.clientProfile` or `viewer.workerProfile` is null, the gateway
adapter writes the sign-up seed (name and email for a requester, name and an
empty zone for a professional) and uses the answer.

## Referral codes

Codes look like `RP-1a2b3c4d` and match exactly, case included, so
`GatewayReferralLinker` only trims whitespace. The requester enters one from
Perfil → "¿Tienes un código?"; an unknown code reads "Ese código no existe".

## Adapters

| Port | Live | Offline and tests |
|---|---|---|
| `ClientProfileRepository` | `GatewayClientProfileRepository` | `MockClientProfileRepository` |
| `ProviderProfileRepository`, `ProviderProfileEditor` | `GatewayProviderProfileRepository` | `MockProviderProfileRepository` |
| `ReferralLinker` | `GatewayReferralLinker` | `MockReferralLinker` |

`offlineMarketplaceProvider` picks between them, as for the wallet.
