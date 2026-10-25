# REQ-03 Booking Flow (Requester)

A requester picks one of a professional's open slots for an offer and books it,
or proposes a different time as a service request.

## Screens and routes

| Route | Screen | Notes |
|---|---|---|
| `/home/book/:offerId` | `BookingScreen` | Full screen, above the nav bar (`parentNavigatorKey: rootKey`). |

All steps live inside `apps/requester/lib/features/booking/`; no extra routes.

| File | What it draws |
|---|---|
| `booking_screen.dart` | Loads the offer (loading / missing / error states) and switches between the steps with `ManoStepTransition`. System back on the proposal step returns to the pick step. |
| `booking_pick_step.dart` | Summary (service title, `ManoPriceTag`, hourly note), `ManoDateStrip` over 14 days (days without a bookable slot are disabled), `ManoSlotGrid` for the chosen day (taken slots disabled), a failure `ManoNotice`, the primary **Continuar** and the quiet **Proponer otro horario**. |
| `booking_propose_step.dart` | Multiline `ManoTextField` message, `ManoDateStrip` (all 14 days), hour chips 7 a. m.–6 p. m. (past hours disabled), primary **Enviar solicitud**. |
| `booking_sheets.dart` | `showConfirmBookingSheet` (`ManoPromptSheet` summarising service, `ManoFormat.dateTime` and price), `showAccountNeededSheet` (`ManoAccountNeededSheet`, shared with the provider app; guests → **Iniciar sesión** → `onboardingFlowProvider.notifier.startSignIn()`), `priceLabels`, `isSignedIn`. |
| `booking_done_view.dart` | Success: "¡Listo! Tu cita quedó agendada" or "Solicitud enviada", with **Ver en Actividad** (`/projects`) and **Volver al inicio** (`/home`). |

Price copy: fixed → `$120.000 precio fijo`; hourly → `$45.000 /hora` plus
"El precio final depende de las horas trabajadas."

## State flow

All in `packages/mano_session/lib/src/booking/booking_notifier.dart`.

- `availableSlotsProvider` — `FutureProvider.autoDispose.family<List<AvailableSlot>, SlotRange>`,
  where `SlotRange = ({String workerId, DateTime from, DateTime to})`. Reads
  `AvailabilityRepository.slotsFor`.
- `bookingProvider` — `NotifierProvider.autoDispose.family<BookingNotifier, BookingState, String offerId>`.
  - `BookingState`: `days` (14 local midnights from today), `selectedDay`,
    `selectedSlot`, `status`, and `range` (`from` first day, `to` day after the last).
  - `BookingStatus` (sealed): `BookingIdle`, `BookingSubmitting`,
    `BookingFailed(DataFailure)`, `BookingBooked(Job)`, `BookingRequested(ServiceRequest)`.
  - `selectDay(day)` clears the slot and any failure; `selectSlot(start)` clears any failure.
  - `confirm()` → `JobRepository.bookSlot(offerId, selectedSlot)`. `Ok` →
    `BookingBooked` and **invalidates `myJobsProvider`**. `Err` → `BookingFailed`,
    selection kept.
  - `propose(message:, start:)` → `ServiceRequestRepository.request(...)`. `Ok` →
    `BookingRequested` and **invalidates `myServiceRequestsProvider`**.
  - Both ignore a second call while submitting and stop if the provider was
    disposed mid-call (`ref.mounted`).

The guest gate is in the screen: `sessionProvider.value is! SignedIn` turns
**Continuar** and **Enviar solicitud** into the account-needed sheet.

The proposal form (message, day, hour) is local widget state; only the
submission goes through the notifier.

## Ports and adapters

| Port | Provider | Adapter today |
|---|---|---|
| `ServiceCatalog.offer` / `.service` | `serviceOfferProvider`, `jobServiceProvider` | `GatewayServiceCatalog` (live) |
| `AvailabilityRepository.slotsFor` | `availableSlotsProvider` | `MockAvailabilityRepository` |
| `JobRepository.bookSlot` | `bookingProvider` | `MockJobRepository` |
| `ServiceRequestRepository.request` | `bookingProvider` | `MockServiceRequestRepository` |

## Shared widgets

No new widgets. `ManoTextField` gained optional `minLines` / `maxLines`
(default `maxLines: 1`, unchanged behaviour) for the proposal message.

## Tests

- `packages/mano_session/test/booking/booking_notifier_test.dart` (8): window,
  selection, booking success + `myJobsProvider` refresh, failure keeps the
  selection, no-slot no-op, proposal success + `myServiceRequestsProvider`
  refresh, proposal failure, slots provider.
- `packages/mano_ui/test/widgets/mano_text_field_test.dart`: +1 for multiline.
- `apps/requester/test/features/booking/booking_screen_test.dart` (10): fixed
  and hourly summary, disabled days, slot grid, Continuar disabled without a
  slot, confirm → success → `/projects`, failure notice keeps the selection,
  guest → sign-in, proposal → "Solicitud enviada", missing offer. Fakes in
  `booking_fakes.dart`. It pumps its own container because `pumpRouterAt`
  already overrides `sessionRepositoryProvider` as signed out.
- `apps/requester/integration_test/booking_flow_test.dart`: signed in, fake
  catalog (offer `offer-1`, `offerantId: provider-1`), first enabled day and
  slot → Continuar → Confirmar → success, and `jobRepositoryProvider.mine()`
  contains the new job.

## Backend gaps blocking go-live

- `AvailabilityRepository` (`workerAvailability`) and `JobRepository`
  (`bookSlot`) are gateway stubs; the scheduler and taskmanager implement them
  but are not wired (docs/develop/backend-contract.md).
- `ServiceRequestRepository.request` is likewise mocked.
- `MockJobRepository.bookSlot` does not check the slot is still free; the real
  backend must reject a taken slot (it would surface as `DataRejected` and
  render through the existing failure notice).
- No auth backend yet, so on a real build every user is a guest and only sees
  the account-needed sheet.
