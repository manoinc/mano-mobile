# REQ-02 · Offers List (Requester)

Every active offer for one service, cheapest first, so the requester can pick
one and book it.

## Screens and routes

| Route | Screen | File |
|---|---|---|
| `/home/service/:id/offers` | `OffersScreen(serviceId:)` | `apps/requester/lib/features/offers/offers_screen.dart` |

Leaves to `/home/book/<offerId>` (REQ-03) with `context.push`, from a tap on
the card or its "Agendar" text action.

### Layout

- **Header:** the service title (`jobServiceProvider`) and "Ofertas disponibles".
- **Filter:** `ManoProjectFilterTabs` with "Todas" / "Precio fijo" / "Por hora".
- **List:** one `ManoOfferCard` per offer:
  - neutral avatar (`ManoInitialsAvatar('P')`) and the title "Profesional"
  - pricing model as the subtitle ("Precio fijo" / "Por hora")
  - zone ("Zona: Chapinero", or "Sin zona definida" when `!offer.hasZone`)
  - `ManoPriceTag` with `ManoFormat.cop(amountCop)` and "precio fijo" or "/hora"
  - a quiet `ManoTextAction` "Agendar"
- **States:**
  - Loading: a spinner.
  - Empty: "Aún no hay ofertas para este servicio", with "Volver".
  - Filter matches nothing: "No hay ofertas con este tipo de precio".
  - Error: "No pudimos cargar las ofertas", with "Reintentar".

The list has no flame button. The empty and error states each have one.

## State flow

- `offersForServiceProvider(serviceId)` (shared, `marketplace_providers.dart`)
  loads the list through `ServiceCatalog.offersFor`.
- `jobServiceProvider(serviceId)` (shared) loads the header title.
- `OfferPricingFilter` (`mano_session/lib/src/offers/offer_pricing_filter.dart`)
  is an enum: `all`, `fixed`, `hourly`. `apply(offers)` filters by `RateType`
  and sorts by `amountCop` ascending. It returns a new list and leaves the
  input alone. This is the only sort; the screen has no sort UI.
- The selected filter is local widget state (`_OffersScreenState._filter`).
  Nothing else needs it.
- "Reintentar" invalidates `offersForServiceProvider(serviceId)` and
  `jobServiceProvider(serviceId)`.
- Nothing invalidates these providers from this screen otherwise. If
  REQ-03 or PROV-02 change an offer, they should invalidate
  `offersForServiceProvider` themselves.

## Ports and adapters

| Port | Adapter (default) | Status |
|---|---|---|
| `ServiceCatalog` | `GatewayServiceCatalog` | live, public |

Tests override `serviceCatalogProvider` with `FakeServiceCatalog`
(`apps/requester/test/features/offers/fake_service_catalog.dart`).

## Shared widgets added

`ManoOfferCard` (`packages/mano_ui/lib/src/widgets/mano_offer_card.dart`):

```dart
ManoOfferCard({
  required String title,
  required String subtitle,
  required String amountLabel,
  required String rateLabel,
  required String zone,
  Widget? leading,    // avatar
  Widget? status,     // e.g. ManoStatusChip; for PROV-02 (Activa / Pausada)
  Widget? trailing,   // a quiet action beside the price
  VoidCallback? onTap,
})
```

PROV-02 can reuse it for a provider's own offers:

- `title` is the service name.
- `leading` is left out.
- `status` is a `ManoStatusChip`.

## Tests

| Suite | File | Count |
|---|---|---|
| mano_session | `test/offers/offer_pricing_filter_test.dart` | 4 |
| mano_ui | `test/widgets/mano_offer_card_test.dart` | 4 |
| requester (widget) | `test/features/offers/offers_screen_test.dart` | 9 |
| requester (device) | `integration_test/offers_flow_test.dart` | 1 |

The device flow does this:

1. Boots the app signed in, with a fake catalog.
2. Goes to `/home/service/svc-1/offers`.
3. Filters by "Por hora".
4. Taps the remaining offer.
5. Asserts the path is `/home/book/hourly`.

## Backend gaps

- **No provider identity on an offer.** `jobServiceOffer` and
  `offersByJobService` return only `offerantId`, with no name, photo, rating
  or review count. Cards show a neutral "P" avatar and "Profesional". When
  the gateway resolves the offerant, add the name and photo, and probably a
  `ManoPersonRow`-style rating, to the card mapping. No `mano_ui` change is
  needed: `leading` and `title` are already slots.
- **No server-side filter or sort.** Filtering by rate type and sorting by
  price happen on the client. That is fine for today's volumes. A large
  catalog would need pagination and `rateType` / `orderBy` arguments on
  `offersByJobService`.
