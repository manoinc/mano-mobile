# REQ-07 Provider Profile (requester)

What a requester sees of a professional before hiring: who they are, what they
do, their work and what other clients said (HU-C1). Rating a finished job is a
separate stream (HU-C6, see [Reviews and ratings](../develop/reviews.md)).

## Screens and routes

| Route | Class | File |
|---|---|---|
| `/provider/:providerId` (root navigator) | `ProviderProfileScreen(providerId:)` | `features/provider_profile/provider_profile_screen.dart` |
| `/provider/:providerId/reviews` (root navigator) | `ProviderReviewsScreen(providerId:)` | `features/provider_profile/provider_reviews_screen.dart` |

The profile sits above the tabs because three tabs open it. Build its path
with `providerProfilePath(id)` (`provider_profile_route.dart`).

### Entry points

- **Offers** (REQ-02): the avatar and title area of each `ManoOfferCard`.
- **Project quotes** (REQ-06): the avatar and name of each `ManoQuoteCard`.
- **Chat** (REQ-05): the header's profile sheet shows "Ver perfil" when the
  other side is a provider, "Cerrar" otherwise.

### Layout

Modelled on Thumbtack's pro profile and Airbnb's host and reviews pages, kept
minimal:

1. **Header**: 96 dp photo, name (`nameOr('Profesional')`), clay verified
   badge, `ManoRatingSummary` (big "4,9", stars, "32 reseñas", or "Aún sin
   reseñas").
2. **Sobre mí** (hidden when the bio is empty), **Especialidades** as pill
   chips, **Trabajos** as `ManoPhotoGallery` or "Aún no hay fotos de trabajos".
3. **Reseñas**: the three newest `ManoReviewTile`s and an outlined "Ver las N
   reseñas" when there are more. The full list pages with `nextCursor`
   ("Ver más"; a failed page keeps what is shown and offers "Reintentar").
4. **Escribir**: the one flame button, pinned at the bottom. A guest is asked
   to sign in; otherwise `conversationActionsProvider.open(withWorkerId:)` and
   the chat opens.

States: a stone skeleton while loading, "No encontramos a este profesional"
when the directory has no such id, and "No pudimos cargar el perfil" with
Reintentar on any other failure.

### Stars on cards

`ManoOfferCard` and `ManoQuoteCard` take an optional `ratingLabel` + `rated`
and show a `ManoRatingBadge` on the subtitle line, so a rating never makes a
card taller. The screen feeds it from `providerRatingProvider(id)`:
"4,9 · 32", or "Nuevo" (clay, no star) with no reviews. While the rating loads
the badge is hidden. All copy comes from `rating_labels.dart`
(`ratingAverageText`, `reviewsCountText`, `ratingBadgeText`).

## State (`mano_session/lib/src/reviews/`)

| Provider | What |
|---|---|
| `providerProfileViewProvider(id)` | `ProviderProfileView` (profile + rating + first `ReviewPage`). `null` on `DataNotFound`; other directory failures are errors (no silent retries). Ratings fall back to `RatingSummary.none`, reviews to an empty page. |
| `providerReviewsFeedProvider(id)` | `ReviewFeed` (items, cursor, `loadingMore`, `loadMoreFailed`) with `loadMore()`. |

## Backend gaps

- `ProviderDirectory` is mock-only (`MockProviderDirectory` knows `provider-1`
  and `provider-2`); the gateway has no `workerProfile(id)`. Live, every
  profile is "No encontramos a este profesional" until it does.
- Live ratings and reviews only read through a job the requester shares with
  that provider, so strangers on offer cards show "Nuevo".
- Offers carry only `offerantId`, so offer cards still say "Profesional".

## Tests

- `packages/mano_session/test/reviews/provider_profile_view_test.dart`
- `packages/mano_ui/test/widgets/mano_rating_badge_test.dart`, plus the offer
  and quote card tests
- `apps/requester/test/features/provider_profile/`, and the offers, project
  detail and chat screen tests for the entry points
- Device: `integration_test/offers_flow_test.dart` (offer → profile → reviews →
  Escribir)
