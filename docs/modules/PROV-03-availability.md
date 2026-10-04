# PROV-03 Availability & Calendar (provider)

Flow T-2 step 3: the professional sets the days and hours they take work,
blocks dates they won't work, and can subscribe to their Mano jobs from Google
Calendar or Apple Calendar. Rule and block changes show up straight away in the
requester's booking calendar (`availableSlotsProvider`).

## Screens and routes

| Route | Class | File |
|---|---|---|
| `/services/availability` (pushed from Servicios) | `AvailabilityScreen` | `apps/provider/lib/features/availability/availability_screen.dart` |

Other files in `features/availability/`:

| File | Holds |
|---|---|
| `availability_labels.dart` | `weekdaysLabel`, `minutesLabel`, `ruleLabel`, `blockLabel` (pure, unit tested) |
| `availability_parts.dart` | `AvailabilitySection` (title, detail, header action), `AvailabilityLoadError`, `AvailabilityQuiet`, `AvailabilityLoading` |
| `rule_editor_sheet.dart` | `RuleEditorSheet({AvailabilityRule? rule})` |
| `block_dates.dart` | `blockDates(context, ref)`: date range picker, then a reason sheet |
| `calendar_feed_section.dart` | `CalendarFeedSection` |

The entry link on the Servicios tab ("Disponibilidad y calendario") is PROV-02's.

### Horario semanal

- Each rule is a `ManoOptionRow` keyed `rule-<id>`, reading e.g.
  "lun – vie · 8:00 a. m. – 12:00 p. m.".
  - Three or more consecutive weekdays collapse into a range.
  - Shorter runs are listed ("sáb, dom").
  - All seven days read "Todos los días".
- Tapping a rule, or "Agregar horario", opens `RuleEditorSheet` in
  `showManoSheet`. The sheet has:
  - `ManoWeekdayPicker` for the days.
  - "Desde" and "Hasta" dropdowns on 30-minute steps. "Desde" runs from 0:00
    to 23:30; "Hasta" from 0:30 to midnight. A new rule starts at
    8:00–12:00 with no days selected.
  - Inline errors: "Elige al menos un día.", "La hora de fin debe ser después
    del inicio.", then `rule.isValid` as a final check. A `DataRejected` from
    the port reads "Revisa los días y las horas.".
  - "Guardar" (the sheet's flame) calls `saveRule`. When editing, "Eliminar
    horario" calls `deleteRule`. On success the sheet closes itself.

### Fechas bloqueadas

- Each block reads "12 oct – 14 oct · Vacaciones" (one day: "12 oct").
  - Blocks are stored with an exclusive end, the midnight after the last day,
    so the label subtracts a day.
  - The × button ("Quitar bloqueo") calls `unblock`. There is no swipe to
    remove: a `Dismissible` would have to leave the tree before the async
    unblock finishes.
- "Bloquear fechas":
  - opens `showDateRangePicker` from today to a year ahead, with Spanish
    help, save and cancel text;
  - then shows a `ManoPromptSheet` with an optional "Motivo" field;
  - then calls `block(start, lastDay + 1 day, reason:)`.

### Sincroniza tu agenda

- With no feed, it shows the screen's only flame: "Generar enlace" (`issueFeed`).
- With a feed, it shows:
  - the URL, truncated to one line;
  - "Copiar enlace" (outline): `Clipboard.setData` plus the snackbar
    "Enlace copiado";
  - "Generar nuevo enlace" (quiet): a confirm sheet warns that the previous
    link stops working, then `issueFeed`;
  - "Desactivar enlace" (quiet): `revokeFeed`.

Every section has loading, empty and error ("No pudimos cargar …" +
"Reintentar") states. A failed mutation shows `failure.message` in a snackbar
or, in the rule sheet, inline.

## State

`packages/mano_session/lib/src/availability/availability_providers.dart`:

| Provider | Type | Reads |
|---|---|---|
| `myAvailabilityRulesProvider` | `FutureProvider<List<AvailabilityRule>>` | `myRules()` |
| `myCalendarBlocksProvider` | `FutureProvider<List<CalendarBlock>>` | `myBlocks()` |
| `myCalendarFeedProvider` | `FutureProvider<CalendarFeed?>` | `myFeed()` |
| `availabilityActionsProvider` | `NotifierProvider<AvailabilityActions, void>` | mutations |

`AvailabilityActions` returns the port's `Result`. On success it invalidates:

| Method | Invalidates |
|---|---|
| `saveRule(rule)`, `deleteRule(id)` | `myAvailabilityRulesProvider`, `availableSlotsProvider` (whole family) |
| `block(start, end, {reason})`, `unblock(id)` | `myCalendarBlocksProvider`, `availableSlotsProvider` |
| `issueFeed()`, `revokeFeed()` | `myCalendarFeedProvider` |

## Ports and adapters

- `AvailabilityRepository` through `availabilityRepositoryProvider`, which
  defaults to `MockAvailabilityRepository`. The mock is seeded with three
  rules (lun – vie mornings and afternoons, sáb mornings), no blocks and no
  feed.
- Mock state lives for as long as the provider container does.

## Shared widgets added

- `ManoWeekdayPicker({required Set<int> selected, required ValueChanged<int>
  onToggle})` in `mano_ui`.
  - Seven round toggles L M X J V S D. Days are 1 (Monday) to 7 (Sunday).
  - A selected day is filled ink; an unselected one is a quiet surface.
  - Each toggle is announced as a selectable button with the full day name.

## Tests

| Suite | File | Cases |
|---|---|---|
| mano_session | `test/availability/availability_providers_test.dart` | 9: reads; save, reject and delete rules; block and unblock; slots refresh after a rule or block change; issue and revoke feed |
| mano_ui | `test/widgets/mano_weekday_picker_test.dart` | 3 |
| provider | `test/features/availability/availability_labels_test.dart` | 7 |
| provider | `test/features/availability/availability_screen_test.dart` | 7: list, error state, add a Sunday rule, inline validation, edit and delete, remove a block, issue, copy, reissue and revoke the feed |
| provider (device) | `integration_test/availability_flow_test.dart` | signed in → Servicios → push `/services/availability` → add dom 10:00–12:00 → Generar enlace → Desactivar |

The date range picker has no widget test. In the test font its header
overflows, and the Material picker is brittle to drive. The block call it
leads to is covered in mano_session, and the flow is left for the device.

## Backend gaps blocking go-live

- Scheduling is a stub on mano-gateway. `workerAvailability`,
  `myAvailabilityRules`, `upsertAvailabilityRule`, `removeAvailabilityRule`,
  `blockCalendar` and `unblockCalendar` exist in the scheduler but are not
  wired (docs/backend-contract.md).
- No GraphQL operation exists to issue or revoke a calendar feed, and there is
  no `.ics` route. The scheduler has to implement both before "Sincroniza tu
  agenda" can be real. Mock URLs look like
  `https://api.mano.co/calendars/mock-<n>.ics`.
- Going live needs a `GatewayAvailabilityRepository` in `mano_data` and a new
  default in `marketplace_providers.dart`. Nothing in this module changes.
- The apps don't configure `flutter_localizations`, so the date range picker's
  month and weekday names are in English. Only the button and help text are
  set in Spanish.
