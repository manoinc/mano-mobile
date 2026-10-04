# PROV-02 · My Services & Offers (Provider)

The provider's own offers: list them, publish a new one, edit the price, pause,
reactivate or delete. It is also the way into availability (PROV-03).

## Screens and routes

| Route | Screen | File |
|---|---|---|
| `/services` (Servicios tab) | `MyServicesScreen()` | `apps/provider/lib/features/services/my_services_screen.dart` |
| `/services/new` (full screen; also the centre "+") | `OfferEditorScreen()` | `apps/provider/lib/features/services/offer_editor_screen.dart` |
| `/services/offer/:id` (full screen) | `OfferEditorScreen(offerId:)` | same |

`offer_labels.dart` maps domain to copy: `pricingModel` ("Precio fijo" /
"Por hora"), `rateLabel` ("precio fijo" / "/hora", the same as REQ-02), and
`offerBadge` (Activa → success, Pausada → neutral).

### My services

- **Header:** "Mis servicios".
- **Availability entry:** a quiet row, "Disponibilidad y calendario", that runs
  `context.push('/services/availability')`. That screen belongs to PROV-03.
- **List:** one `ManoOfferCard` per offer:
  - title: the service title, or "Servicio" while unknown
  - subtitle: the pricing model
  - `ManoFormat.cop(amountCop)` plus the rate label
  - "Zona: X", or "Sin zona definida"
  - a `ManoStatusChip` reading Activa or Pausada
- Tapping a card pushes `/services/offer/<id>`.
- **States:**
  - Loading: a spinner.
  - Empty: "Aún no ofreces ningún servicio", with the CTA "Publicar mi primer
    servicio" → `/services/new`.
  - Error: "No pudimos cargar tus servicios", with "Reintentar".

### Offer editor

- **Servicio:**
  - New offer: a `ManoSearchField` (debounced 300 ms) over the live catalog
    (`serviceSearchProvider`), showing up to 6 results. Tapping a result
    selects it, and a check marks the selection.
  - Editing: the service is fixed and shown as read-only text.
- **Tipo de precio:** `ManoProjectFilterTabs`, "Precio fijo" / "Por hora".
- **Amount:** a numeric `ManoTextField`, labelled "Precio (COP)" or "Valor por
  hora (COP)". Non-digits are stripped, so "50.000" becomes 50000. A
  `ManoPriceTag` below it previews the price live.
- **Zona (opcional):** free text, trimmed on save.
- **Validation:** a service is picked and the amount is above 0. Until then the
  primary button is disabled.
- **Primary (flame):** "Publicar" when new, "Guardar cambios" when editing.
- **Editing only:** two quiet buttons. The first is "Pausar" or "Reactivar",
  depending on the offer's status. The second is "Eliminar", which asks first
  through `showManoDialog` + `ManoDialogCard`.
- **Results:**
  - `Ok`: the screen pops back to the list, which has already been refreshed.
  - `Err`: a `ManoNotice` (error tone) shows `failure.message`, and the screen
    stays put.
- **Load error** (editing an unknown or unreachable offer): "No pudimos cargar
  esta oferta", with "Reintentar".

## State flow

Everything below lives in `packages/mano_session/lib/src/services/`.

- `myOffersProvider`: a `FutureProvider<List<ServiceOffer>>` over
  `OfferManagement.myOffers()`. No auto-retry, because the screen offers
  "Reintentar".
- `offeredServiceProvider(id)`: a `FutureProvider.family<JobService?, String>`
  over `ServiceCatalog.service`. It is `jobServiceProvider` without
  auto-retry. A title that fails to load just falls back to "Servicio". Without
  this, the shared provider's retry timers kept running whenever the gateway
  was unreachable, tests included.
- `offerEditorProvider(String? offerId)`: an
  `AsyncNotifierProvider.autoDispose.family` building `OfferEditorNotifier`,
  with no auto-retry.
  - `build()`:
    - `null` id: an empty draft (fixed price, 0, no zone).
    - Otherwise: reads `OfferManagement.myOffers()`, finds the offer and seeds
      the draft from it. An unknown id throws a `StateError`, which the screen
      shows as the error state.
    - The offers are read, not watched, so the notifier's own invalidations
      never reset the draft.
  - `OfferEditorState`: `original` (null when new), `jobServiceId`, `rateType`,
    `amountCop`, `zone` and `status`. Getters: `isNew`, `isValid`, `isBusy`.
  - `OfferEditorStatus`: `Idle`, `Submitting`, `Failed(DataFailure)` or
    `Saved(ServiceOffer)`.
  - Draft setters: `selectService` (ignored when editing), `setRateType`,
    `setAmount` and `setZone`. Each one clears a failure.
  - Mutations: `submit()` (create or update), `pause()`, `resume()` and
    `delete()`. Each is ignored while a mutation is already running.
  - **A successful mutation invalidates** `myOffersProvider` and
    `offersForServiceProvider(offer.jobServiceId)`, so the requester's offer
    list (REQ-02) stays current too.
- The screen `ref.listen`s for `OfferEditorSaved` and calls `context.pop()`.

## Ports and adapters

| Port | Adapter (default) | Status |
|---|---|---|
| `OfferManagement` | `MockOfferManagement` | mock |
| `ServiceCatalog` | `GatewayServiceCatalog` | live, public |

## Shared widgets added

None. The module reuses `ManoOfferCard`, `ManoStatusChip`, `ManoSearchField`,
`ManoProjectFilterTabs`, `ManoTextField`, `ManoPriceTag`, `ManoPrimaryButton`,
`ManoQuietButton`, `ManoNotice`, `ManoEmptyState` and `showManoDialog` /
`ManoDialogCard`.

## Tests

| Suite | File | Count |
|---|---|---|
| mano_session | `test/services/offer_editor_notifier_test.dart` | 12 |
| mano_session | `test/services/my_offers_provider_test.dart` | 2 |
| provider (widget) | `test/features/services/my_services_screen_test.dart` | 5 |
| provider (widget) | `test/features/services/offer_editor_screen_test.dart` | 7 |
| provider (device) | `integration_test/services_flow_test.dart` | 1 |

The fakes are `FakeServiceCatalog` and `FakeOfferManagement`, in
`test/features/services/services_fakes.dart`.

The device flow runs signed in, with both fakes:

1. Servicios tab → "+".
2. Picks "Reparación de fugas".
3. Sets "Por hora", 50000 and zone "Suba", then taps Publicar.
4. The card appears marked Activa.
5. Opens it → Pausar.
6. The card shows Pausada.

`provider_router_test.dart`'s "offer editor" test was split in two. Pumping a
second router in the same test stranded the first container's autoDispose
timer.

## Backend gaps

- **No auth.** `createJobServiceOffer`, `updateJobServiceOffer`,
  `pauseJobServiceOffer` and `deleteJobServiceOffer` exist on the gateway but
  require an authenticated provider, and no auth backend is wired yet.
- **No "list my offers" query.** `myOffers()` has nothing to call. The gateway
  needs something like `myJobServiceOffers` (offers by the caller's
  `offerantId`).
- **No resume.** The gateway can pause but not reactivate an offer. "Reactivar"
  works only against the mock.
- Until all three exist, `offerManagementProvider` stays on
  `MockOfferManagement`. Swapping it is a `GatewayOfferManagement` in
  `mano_data` plus one line in `marketplace_providers.dart`; these screens do
  not change.
