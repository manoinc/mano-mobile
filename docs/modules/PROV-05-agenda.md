# PROV-05 Jobs Agenda (provider)

The provider's "Agenda" tab and the job detail screen. This is where a
professional sees what's next, starts and finishes work (logging hours on hourly
jobs), and cancels.

## Screens and routes

| Route | Class | File |
|---|---|---|
| `/agenda` | `AgendaScreen` | `apps/provider/lib/features/agenda/agenda_screen.dart` |
| `/agenda/job/:id` | `AgendaJobScreen(jobId:)` | `features/agenda/agenda_job_screen.dart` |

### Agenda tab

The header reads "Agenda", above a `ManoProjectFilterTabs` row:

| Filter | Jobs | Order |
|---|---|---|
| Calendario (default) | every job | a `ManoMonthCalendar` (dots on days with jobs) over the selected day's jobs, today first |
| En curso | `inProgress` | repository order |
| Historial | `finished` and `cancelled` | newest first |

- **Day header under the calendar.** The selected day gets a header: "Hoy", "Mañana", or
  otherwise `ManoFormat.weekdayShort` + `dayMonth` (for example "vie 9 oct").
- **Cards.** Every job is a `ManoProjectCard` keyed `agenda-job-<id>`, with the
  **client** in the "professional" slots. A card shows:
  - the service title
  - the client's name and photo
  - the time: just the hour under the calendar, since the header already gives the
    day, and `ManoFormat.dateTime` elsewhere
  - the price (`ManoFormat.cop`, plus `/hora` for hourly jobs)
  - a `ManoStatusChip`
- **Tap.** Tapping a card runs `context.push('/agenda/job/<id>')`.
- **Empty state.** Each filter has its own `ManoEmptyState` message. The CTA
  "Ver solicitudes" goes to `/requests`.
- **Loading and errors.** Loading shows a spinner. An error shows "No pudimos
  cargar tu agenda." with "Reintentar", which invalidates `myJobsProvider`.

### Job detail

The screen shows:

- the status chip
- the service title
- `ManoPriceTag`, with "por hora" or "precio fijo"
- the client (`ManoAvatar`, name, and "Cliente"; just "Cliente" while nameless)
- the weekday and date, then the start time

`ManoPersonRow` wasn't used because it requires a rating, and clients don't
have one.

A **finished hourly** job also shows "Horas registradas" (for example "2,5 h")
and "Total" (`hours × rate`).

The bottom bar has one flame action, chosen by the job's state:

- `canStart` shows **"Iniciar trabajo"**, which calls `AgendaActions.start`.
- `canFinish` shows **"Finalizar trabajo"**:
  - On a fixed-price job it opens a `ManoPromptSheet` ("¿Finalizar este
    trabajo?" / "Sí, finalizar") and then calls `finish(id)`.
  - When `requiresHoursOnFinish` is true it opens the hour logger instead.
- `canCancel` adds a quiet **"Cancelar trabajo"** below the main action. It
  opens a sheet with an optional reason (`ManoTextField`). "Sí, cancelar" calls
  `activityActionsProvider.cancelJob`.

Every action reports its outcome in a snackbar: "Trabajo iniciado.", "Trabajo
finalizado.", "Trabajo cancelado.", or `failure.message`.

Before it opens a sheet, the screen dismisses any visible snackbar. The
snackbar lives on the shell's scaffold, and otherwise it covers the sheet's
button.

Other states:

- An unknown id shows "No encontramos este trabajo." with "Volver a la agenda"
  (`/agenda`).
- A load error shows "No pudimos cargar este trabajo." with "Reintentar".

### Hour logger

`HourLoggerSheet(initialHours:, rateCop:)` lives in
`features/agenda/hour_logger_sheet.dart`. It's a `ManoPromptSheet` that pops a
`double`, or `null` if the provider dismisses it.

- **Stepper.** The − and + buttons (keys `hour-logger-minus` and
  `hour-logger-plus`) move the time in 0.5 h steps. The minimum is 0.5 h, and −
  is disabled once it's reached.
- **Prefill.** The sheet opens with `loggedHoursSince(job.start, now)`: the time
  since the job's start, rounded to the nearest 0.5 h.
- **Total.** A live line reads "Total $X", computed as
  `ManoFormat.cop(hourlyTotalCop(hours, amountCop))`.
- **Confirm.** "Confirmar" calls `finish(id, actualHours: hours)`.

## State flow

Everything below lives in `packages/mano_session/lib/src/agenda/`.

`agenda_providers.dart`:

| Provider / function | Type | Reads |
|---|---|---|
| `upcomingJobsProvider` | `FutureProvider<List<Job>>` | `jobsByStatusProvider(scheduled)`, sorted by `start` |
| `jobHistoryProvider` | `FutureProvider<List<Job>>` | `myJobsProvider` (finished and cancelled), newest first |
| `groupJobsByDay(List<Job>)` | `List<JobDay>`, where `JobDay = ({DateTime day, List<Job> jobs})` | pure |
| `agendaClockProvider` | `Provider<DateTime Function()>` | `DateTime.now`; tests override it |
| `agendaActionsProvider` | `NotifierProvider<AgendaActions, void>` | mutations, below |

`AgendaActions` methods return `Result<Job, DataFailure>`. Only a success
(`Ok`) invalidates anything:

| Method | Port call | Invalidates on `Ok` |
|---|---|---|
| `start(id)` | `JobRepository.start` | `myJobsProvider`, the whole `jobProvider` family |
| `finish(id, {actualHours})` | `JobRepository.finish` | `myJobsProvider`, the whole `jobProvider` family |

Cancelling reuses wave 1's `ActivityActions.cancelJob`, which invalidates the
same two providers.

All three lists derive from `myJobsProvider`, so a single invalidation refreshes
every filter. The same holds for the "En curso" list
(`jobsByStatusProvider(inProgress)`).

`hour_log.dart` is pure, with no Riverpod:

- `loggedHoursSince(DateTime start, DateTime now) → double`: rounds to the
  nearest 0.5 h, never below 0.5
- `addHalfHour(double)`
- `removeHalfHour(double)`: clamped at 0.5
- `canRemoveHalfHour(double) → bool`
- `hourlyTotalCop(double hours, int rateCop) → int`: rounded

Screens keep only presentation state: the selected filter, a busy flag, and the
hours on the sheet.

## Ports and adapters

- `JobRepository`, served by `MockJobRepository`, because the gateway stubs
  jobs. The mock enforces the lifecycle and rejects finishing an hourly job
  without hours > 0 (`DataRejected`).

## Shared widgets

No new `mano_ui` widgets, and no existing widget changed. The module reuses:

- `ManoProjectFilterTabs`
- `ManoProjectCard`
- `ManoStatusChip`
- `ManoEmptyState`
- `ManoPromptSheet` / `showManoSheet`
- `ManoPriceTag`
- `ManoAvatar`
- `ManoTextField`
- `ManoPrimaryButton`, `ManoQuietButton`

These helpers are local to the app, in `features/agenda/`:

- `agenda_labels.dart`: `jobBadge`, `shortPrice`, `rateLabel`, `dayLabel`,
  `hoursLabel`
- `agenda_load_error.dart`
- `hour_logger_sheet.dart`

`jobBadge`, `shortPrice`, `rateLabel` and the load-error widget mirror the
requester's `features/activity/` copies. Apps can't import each other, so a
shared copy would have to move into `mano_session` or `mano_ui`.

## Tests

- `packages/mano_session/test/agenda/hour_log_test.dart`: rounding, the
  minimum, stepping, and the total.
- `packages/mano_session/test/agenda/agenda_providers_test.dart`:
  - the sort order of both selectors
  - `groupJobsByDay`
  - `start` and `finish`: their results, invalidation, and rejecting a finish
    without hours
  - a failure doesn't invalidate anything
- `apps/provider/test/features/agenda/agenda_labels_test.dart`
- `apps/provider/test/features/agenda/agenda_screen_test.dart`:
  - each filter's contents and order
  - day headers
  - card mapping
  - navigation
  - empty states and their CTA
  - the error state
- `apps/provider/test/features/agenda/agenda_job_screen_test.dart`:
  - details
  - start
  - finishing a fixed job
  - finishing an hourly job: prefill (with a pinned clock), stepping, the live
    total, and the logged summary
  - the 0.5 h floor
  - cancelling with a reason
  - not found
  - the error state
- `apps/provider/test/features/agenda/agenda_flow_test.dart`: a host twin of
  the device flow.
- `apps/provider/integration_test/agenda_flow_test.dart`: the device flow,
  signed in, on the default mocks:
  1. Agenda → Próximos → job-1 (fixed) → Iniciar → Finalizar → Sí, finalizar →
     Finalizado.
  2. Back → En curso → job-3 (hourly) → Finalizar → step down to the minimum,
     then + ×4 → 2.5 h → Confirmar → Finalizado, showing "2,5 h" and $112.500.

## Backend gaps

- The gateway stubs jobs (`docs/develop/backend-contract.md`), so `JobRepository` is a
  mock.
- `Job` doesn't record when work actually started. The hour logger prefills
  from the **scheduled** `start`, so a job started late or early prefills
  inaccurately. A `startedAt` field set by `start()` would fix this, but that
  means changing the domain and the mock, which this module isn't allowed to do.
- The mock drops `cancel(reason:)`.
- Who may start, finish or cancel isn't enforced (any signed-in role can). The
  backend should check that the caller is the job's provider.
- There's no live refresh. A cancellation by the client shows up only after this
  app invalidates its job reads.
