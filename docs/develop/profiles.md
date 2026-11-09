# Profiles

Names, contact details, referral codes and verification come from
**mano-profiles** (gRPC), which the gateway stitches onto `viewer`. The photo
comes from mano-media, and ratings come from mano-reviews.

## Gateway to domain

| Gateway | Domain | Port |
|---|---|---|
| `viewer.clientProfile { displayName phone email photoUrl }` | `ClientProfile` | `ClientProfileRepository` |
| `updateClientProfile(input: {displayName photoMediaId phone email})` | `ClientProfile` | `ClientProfileRepository.update` |
| `viewer.workerProfile { displayName phone email photoUrl workZone }` | `ProviderProfile.party`, `zones` | `ProviderProfileRepository.profile` |
| `workerProfile.verification { isVerified verifiedAt }` | `ProviderProfile.verified` | same |
| `workerProfile.averageRating`, `ratingsCount` | `ProviderStats.rating`, `reviewCount` | `ProviderProfileRepository.stats` |
| `workerProfile.referralCode` | `ReferralProgram.code` | `ProviderProfileRepository.referral` |
| `linkWorkerByReferralCode(code)` | the professional's name | `ReferralLinker` |

## Not served yet

| Field | Plan |
|---|---|
| `ProviderStats.jobsCompleted`, `completionRatePct` | STREAM-05 adds them on the gateway (counted from taskmanager) |
| `responseRatePct`, referral progress (`invited`, `goal`, `rewardCoins`) | no backend; stays mocked |
| `bio`, `yearsExperience`, `skills`, portfolio | no backend; stays mocked |

Until a field is served, the screen hides it rather than showing a mock number
next to live ones.

## Adapters

`MockClientProfileRepository`, `MockProviderProfileRepository` and
`MockReferralLinker` serve offline mode and tests. The gateway adapters land
with STREAM-05.
