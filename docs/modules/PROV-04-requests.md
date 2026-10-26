# PROV-04 Incoming Requests (provider)

The provider app's first tab, "Solicitudes": requests clients sent, answered
in place. Covers product flow T-3 steps 1–4: see the request, chat before
deciding, accept or reject with an optional reason, and on accept the work
lands on the agenda.

## Screens and routes

| Route | Class | File |
|---|---|---|
| `/home` | `ProviderHomeScreen` | `apps/provider/lib/features/home/requests_section.dart` |

Supporting files in the same folder:

| File | Holds |
|---|---|
| `request_detail_sheet.dart` | `showRequestDetailSheet` → `RequestDecision?` (`accept`, `reject`, `chat`) |
| `reject_sheet.dart` | `showRejectSheet` → `String?` (`null` = dismissed, `''` = no reason) |
| `request_actions_row.dart` | `RequestActionsRow`: "Rechazar" (`ManoQuietButton`) + "Aceptar" (`ManoOutlineButton`) |
| `request_labels.dart` | status → chip copy/tone, rate copy, "Sin horario propuesto" |

### Solicitudes

- Header "Solicitudes" and `ManoProjectFilterTabs`:

  | Tab | Statuses |
  |---|---|
  | Pendientes (default) | `pending` |
  | Respondidas | `accepted`, `rejected`, `cancelled` |

- Each request is a `ManoRequestCard` keyed `request-card-<id>`: client
  (`ManoAvatar` + name), service title, message (2 lines), proposed time
  (`ManoFormat.dateTime` or "Sin horario propuesto") and `ManoPriceTag`.
  Answered cards carry a `ManoStatusChip` (Aceptada / Rechazada / Cancelada).
- Pending cards hold `RequestActionsRow`. No flame per card: a list of them
  would break the one-primary rule, so "Aceptar" is the ink outline and
  "Rechazar" the clay quiet button. Both go busy while that card's call runs.
- Tapping a card opens the **detail sheet**: client, title, full message,
  "Horario", "Precio" and any "Motivo" (`ManoDetailRow`). Pending requests add
  the same actions plus "Escribir a <cliente>", which goes to `/inbox`.
- **Aceptar** calls `accept`; success shows the SnackBar "Solicitud aceptada ·
  quedó en tu agenda" with the action "Ver agenda" → `context.go('/agenda')`.
- **Rechazar** opens a `ManoPromptSheet` ("¿Rechazar esta solicitud?") with an
  optional multiline `ManoTextField` "Motivo (opcional)"; "Rechazar solicitud"
  confirms. Success shows "Solicitud rechazada". A blank reason is sent as
  `null`.
- Any `Err` shows `failure.message` in a SnackBar and the card stays put.
- States: spinner while loading; `ManoEmptyState` "No tienes solicitudes
  pendientes" / "Aún no has respondido solicitudes" with CTA "Ver mis
  servicios" (`/services`); load error "No pudimos cargar tus solicitudes."
  with "Reintentar" (invalidates `myServiceRequestsProvider`).

## State flow

```
RequestsScreen
  watches requestsByStatusProvider(status)   (wave 1, activity/)
            └─ myServiceRequestsProvider ─ ServiceRequestRepository.mine()
  calls   requestActionsProvider.notifier.accept(id) / reject(id, reason:)
            └─ on Ok: invalidate myServiceRequestsProvider + myJobsProvider
```

`RequestActions` (`packages/mano_session/lib/src/requests/request_actions.dart`):

```dart
final requestActionsProvider = NotifierProvider<RequestActions, void>(...);
Future<Result<ServiceRequest, DataFailure>> accept(String id);
Future<Result<ServiceRequest, DataFailure>> reject(String id, {String? reason});
```

Invalidating `myJobsProvider` is what makes PROV-05's agenda show the new job.
A failed call invalidates nothing.

## Ports and adapters

- `ServiceRequestRepository` → `MockServiceRequestRepository` (via
  `serviceRequestRepositoryProvider`). Its `onAccepted` hook adds a job to
  `MockJobRepository`, so accepting really puts the work on the calendar.
- Seed data: `request-1`, `request-2` pending; `request-3` accepted;
  `request-4` rejected; `request-5` cancelled. All from client "Laura Pérez".

## Shared widgets added

`ManoRequestCard` (`packages/mano_ui/lib/src/widgets/mano_request_card.dart`):

```dart
ManoRequestCard({
  required String clientName, required String clientPhotoUrl,
  required String title, required String message,
  required String scheduleLabel, required String amountLabel,
  required String rateLabel, required VoidCallback onTap,
  String? statusLabel,                       // null hides the chip
  ManoStatusTone statusTone = ManoStatusTone.neutral,
  Widget? actions,                           // slot under the details
})
```

`ManoProjectCard` didn't fit: it has no message line, always shows a status
and has no actions slot.

## Tests

| Suite | File | Covers |
|---|---|---|
| mano_session | `test/requests/request_actions_test.dart` | accept moves to accepted + adds a job; reject stores reason; failed accept leaves jobs alone |
| mano_ui | `test/widgets/mano_request_card_test.dart` | content, 2-line message, optional chip, actions slot, onTap |
| provider | `test/features/home/requests_section_test.dart` | tabs, accept → Respondidas + "Ver agenda" → `/agenda`, reject with "Sin cupo", detail sheet actions, chat link → `/inbox`, Err SnackBar, empty, error + retry |
| provider (device) | `integration_test/requests_flow_test.dart` | signed in, default mocks: accept `request-1`, reject `request-2` with "Sin cupo", both under Respondidas |

## Backend gaps

- `myServiceRequests`, `acceptServiceRequest` and `rejectServiceRequest` are
  gateway stubs, so this screen runs on the mock only
  (docs/develop/backend-contract.md).
- Accepting must create the job server-side; the mock fakes it with
  `onAccepted`.
- "Chat before deciding" can only open the inbox: `ConversationRepository.open`
  takes a worker or a job, and a pending request has neither a job nor (for the
  provider) a worker to write to. A `jobId`-free reference to the request's
  client would let the detail sheet open `/inbox/:conversationId` directly.
- `mine()` doesn't distinguish requests sent from requests received; the
  backend must scope it by the session's role.
