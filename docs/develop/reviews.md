# Reviews and ratings

Both sides rate each other once a job is finished: the requester rates the
provider (HU-C6), and the provider rates the requester (HU-T12). A provider's
average shows on their cards and profile (HU-C1).

## Rules (mano-reviews, D8)

- Only a **finished** job can be rated. The service learns that from
  taskmanager's `JobFinished` over RabbitMQ. Until it has, a write answers
  `FailedPrecondition: …`, which `failure.isNotYetReviewable` detects so the
  screen can say "Aún no puedes calificar este trabajo".
- `reviewWorker` is for the job's client and `reviewClient` for its worker; the
  service works out who is being reviewed.
- 1–5 stars, an optional comment up to 4000 characters (`ReviewDraft.problems`).
- **Write-once** per job and side. A repeat returns the stored review, not an
  error, and there is no edit or delete.
- Client → worker reviews are public. Worker → client reviews are seen only by
  the two parties.

## Domain (`mano_domain/lib/src/reviews/`)

| Type | What it is |
|---|---|
| `Review` | id, reviewer (`Party`), stars, date, text. Moved here from `profile/`. |
| `ReviewDraft` | stars + comment being written; `problems`, `isValid`, `copyWith`. |
| `RatingSummary` | `average?` (null before the first review) + `count`. `RatingSummary.of(reviews)` averages half up to two decimals, like the service. |
| `ReviewPage` | items, newest first, + `nextCursor` (`hasMore`). |
| `ReviewRepository` | `reviewProvider(jobId, draft)`, `reviewClient(jobId, draft)`, `providerReviews(providerId, {after})`, `providerRating(providerId)`. |
| `PublicProviderProfile` / `ProviderDirectory` | a provider as requesters see them (bio, verified, skills, portfolio), by id. |

## Adapters

- **`GatewayReviewRepository`** writes through `reviewWorker` / `reviewClient`.
  The gateway has **no `workerProfile(id)`**, so reads go through a job the
  caller shares with that provider: `myJobs { id worker { id } }` (cached per
  provider), then `job(id) { worker { averageRating ratingsCount reviews(page) } }`.
  With no shared job the answer is `RatingSummary.none` / an empty page. That
  covers a provider's own Perfil and a requester looking at someone they have
  hired, but not a stranger on an offer card.
- **`MockReviewRepository`** seeds reviews for `provider-1` and `provider-2` and
  is write-once like the service. **`MockProviderDirectory`** is the only
  `ProviderDirectory` until the gateway can look a provider up by id.

## Session (`mano_session/lib/src/reviews/`)

- `reviewRepositoryProvider` (gateway, or mock offline), `providerDirectoryProvider` (mock).
- `providerRatingProvider(providerId)` → `RatingSummary`; a failure shows as
  `none`, because stars on a card are decoration and must not break the card.
- `reviewActionsProvider`: `reviewProvider` / `reviewClient`. A success adds the
  job to `reviewedJobsProvider` and refreshes ratings. The gateway has no
  "already reviewed" field, so that set lasts for the session only.

## UI (`mano_ui`)

| Widget | Use |
|---|---|
| `ManoStarInput` | five large tappable stars with the word under them (Muy malo … Excelente), modelled on Thumbtack's rating step. |
| `ManoRatingSummary` | big average + stars + count (Airbnb / Thumbtack), or "Aún sin reseñas". The screen formats the labels (`4,9`, `32 reseñas`). |
| `ManoReviewTile` | one review, already used on the provider's Perfil. |
| `ManoRatingBadge` | one-line "★ 4,9 · 32" or "Nuevo" for offer and quote cards. |

The requester's view of a provider is [REQ-07](../modules/REQ-07-provider-profile.md).

## Running it locally

Reviews needs RabbitMQ, taskmanager and reviews all on the broker. See
`mano-gateway/docs/local-stack.md`, reviews on `:50056` with `REVIEWS_URL`. Until the
`mano-reviews` branch `fix/jobfinished-routing-key` is merged, reviews listens
on a routing key taskmanager never publishes, so every write is refused.
