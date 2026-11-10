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
| referral counts and reward (`ReferralProgram.invited`, `.verified`, `.coinsPerColleague`) | 0 and null until the gateway serves them; the card then shows the code only. See [Referrals](referrals.md) |
| `bio`, `yearsExperience`, `skills`, portfolio | kept in memory for the session (`localProviderDetailsProvider`), starting blank; hidden while blank |

A screen hides what is not served rather than showing a mock number next to
live ones.

## Missing or blank profiles

mano-profiles has no row for an account until its first write, and leaves a
field it was never given empty.

- Requester: a missing profile, or a blank name, email or phone, reads as the
  sign-up seed. Nothing is written until the person saves.
- Professional: without a row there is no `referralCode` and no
  `WorkerProfile` to carry stats, so when `viewer.workerProfile` is null the
  adapter creates it with the sign-up name (and an empty zone). A blank served
  name also reads as the sign-up name.

## Referral codes

Codes look like `RP-1a2b3c4d` and match exactly, case included, so
`GatewayReferralLinker` only trims whitespace. The requester enters one from
Perfil → "¿Tienes un código?"; an unknown code reads "Ese código no existe".

That is the client saving a professional. Professionals inviting
professionals, with links and coins, is [Referrals](referrals.md).

## Adapters

| Port | Live | Offline and tests |
|---|---|---|
| `ClientProfileRepository` | `GatewayClientProfileRepository` | `MockClientProfileRepository` |
| `ProviderProfileRepository`, `ProviderProfileEditor` | `GatewayProviderProfileRepository` | `MockProviderProfileRepository` |
| `ReferralLinker` | `GatewayReferralLinker` | `MockReferralLinker` |

`offlineMarketplaceProvider` picks between them, as for the wallet.
