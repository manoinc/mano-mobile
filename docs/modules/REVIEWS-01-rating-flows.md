# REVIEWS-01 Rating flows (both apps)

Rating the other side of a finished job, in both apps, and the provider's own
reviews on Perfil. The rules and ports are in
[Reviews and ratings](../develop/reviews.md).

| Story | App | Where |
|---|---|---|
| HU-C6 rate the provider | requester | `/projects/job/:id` (`features/activity/job_detail_screen.dart`) |
| HU-T12 rate the client | provider | `/agenda/job/:id` (`features/agenda/agenda_job_screen.dart`) |
| Own reviews and rating | provider | `/profile`, `/profile/reviews` (`features/profile/`) |

## The rating sheet

One widget, `ManoRatingSheet` (mano_ui), drawn by a thin connector in each app
(`job_rating_sheet.dart`). It follows Thumbtack's rating step:

1. Left-aligned title "¿Cómo te fue con {nombre}?" and a muted subtitle.
2. `ManoStarInput`: five large stars and the word under them. **Enviar** stays
   disabled until a star is chosen.
3. Once a star is chosen, an optional "Comentario (opcional)" field slides in.
4. **Enviar** shows a spinner while sending. A refusal shows as a `ManoNotice`
   above the button and the sheet stays open.
5. On success the form swaps for a thank-you ("¡Gracias por calificar!") with
   **Listo**.

There are no photos: review media upload is still a gateway stub.

| App | Subtitle |
|---|---|
| requester | Tu calificación ayuda a otros a elegir bien. |
| provider | Solo tú y el cliente verán esta calificación. |

## The submit logic (`mano_session/lib/src/reviews/`)

- `ratingFlowProvider(jobId)` (autoDispose): `RatingFlowState` holds the
  `ReviewDraft`, `busy`, the `error` copy and `ratedStars`. `setStars`,
  `setComment` and `submit()`. The app's role picks the side: the requester
  calls `reviewProvider`, the provider calls `reviewClient`.
- `submit` trims the comment and checks `ReviewDraft.problems` before it sends.
  The write goes through `reviewActionsProvider`, so a success lands in
  `reviewedJobsProvider` (jobId → stars) and refreshes ratings.
- `ratedStarsProvider(jobId)` gives the stars this session gave a job. A
  repeat returns the stored review, so its stars (not the draft's) are shown.
- `review_copy.dart` maps failures and draft problems to Spanish:

| Case | Copy |
|---|---|
| `failure.isNotYetReviewable` | Aún no puedes calificar este trabajo. Intenta en unos minutos. |
| any other failure | No pudimos enviar tu calificación. Intenta de nuevo. |
| comment over 4000 | Tu comentario es muy largo. Máximo 4000 caracteres. |

## Job detail bottom bars

**Requester:**

| Job | Actions |
|---|---|
| finished, not rated | **Calificar** (flame) then "Volver a contratar" (outline) |
| finished, rated | **Volver a contratar** (flame) then a disabled quiet "Calificado ★N" |
| cancelled | **Volver a contratar** only |

**Provider:**

| Job | Actions |
|---|---|
| finished, not rated | **Calificar cliente** (flame) |
| finished, rated | a disabled quiet "Calificado ★N" |

The gateway has no "already reviewed" field, so after a restart the button
offers rating again. A repeat is harmless: the service hands back the stored
review, and the sheet thanks the user with those stars.

## Provider Perfil

- `myRatingProvider` reads `providerRatingProvider(subject)` and
  `myReviewsProvider` reads `providerReviews(subject)` a page at a time
  (`loadMore` passes `nextCursor`). The subject comes from `currentUserProvider`.
  A guest gets `RatingSummary.none` and no reviews.
- The "Calificación" stat tile and the public preview's rating come from the
  live rating. Jobs completed, response rate and completion rate stay on the
  mock `ProviderProfileRepository.stats()`.
- `ReviewsScreen` puts `ManoRatingSummary` on top, then the tiles, then "Ver
  más" while there are more pages.
- `ratingLabels(summary)` in `profile_labels.dart` gives "4,9" (or "–" before
  the first review) and "N reseñas".

## Tests

- `mano_session/test/reviews/rating_flow_test.dart` and `my_reviews_test.dart`
- `mano_ui/test/widgets/mano_rating_sheet_test.dart`
- app widget tests through the real router with a fake `ReviewRepository`:
  `job_detail_screen_test.dart`, `agenda_job_screen_test.dart` and
  `provider_profile_screen_test.dart`
- integration tests: requester `activity_flow_test.dart` and provider
  `agenda_flow_test.dart`
