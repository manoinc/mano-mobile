# REQ-04 Activity (requester)

The requester's "Actividad" tab and the job detail screen: what they asked
for, what's booked, what's happening now, and what is over.

## Screens and routes

| Route | Class | File |
|---|---|---|
| `/projects` | `ProjectsTabScreen` → `ActivityTab` | `apps/requester/lib/screens/projects_tab_screen.dart`, `features/activity/activity_tab.dart` |
| `/projects/job/:id` | `JobDetailScreen(jobId:)` | `features/activity/job_detail_screen.dart` |

`ProjectsTabScreen` stays as the class the router builds and just renders
`ActivityTab`.

### Actividad tab

A `ManoProjectFilterTabs` row over one list. Each filter combines jobs and
requests:

| Filter | Jobs | Requests |
|---|---|---|
| Solicitudes (default) | none | `pending` |
| Programados | `scheduled` | none |
| En curso | `inProgress` | none |
| Finalizados | `finished` | none |
| Cancelados | `cancelled` | `rejected`, `cancelled` |

Accepted requests aren't listed, because accepting one creates a job.

Every item is a `ManoProjectCard` showing the service title, the provider's
name and photo, a date (`ManoFormat.dateTime`; for requests the proposed start,
or the creation date if there is none), the price (`ManoFormat.cop`, plus
`/hora` for hourly) and a `ManoStatusChip`. Cards are keyed
`activity-job-<id>` and `activity-request-<id>`.

- Tapping a **job** pushes `/projects/job/<id>`.
- Tapping a **request** opens a `ManoPromptSheet` showing the provider, the
  proposed date, the message and any rejection reason. A pending request's
  sheet offers "Cancelar solicitud". On success a snackbar says "Cancelamos tu
  solicitud." and the card moves to Cancelados. Closed requests only offer
  "Entendido".
- Each filter has its own `ManoEmptyState` message. The CTA, "Explorar
  servicios", goes to `/home`.
- Loading shows a spinner. Errors show "No pudimos cargar tu actividad." with
  "Reintentar", which invalidates both list reads.

### Job detail

The detail screen shows:

- the status chip
- the service title
- `ManoPriceTag`, with "por hora" or "precio fijo"
- the provider (`ManoAvatar` and name)
- the weekday and date, then the start time

It has a single bottom action:

- `job.canCancel` shows **"Cancelar"** (outline button). This opens a
  `ManoPromptSheet` with an optional reason field (`ManoTextField`). Confirming
  ("Sí, cancelar") calls `cancelJob`, and on success a `ManoDialogCard` says
  "Trabajo cancelado".
- `job.canRebook` shows **"Volver a contratar"** (the screen's one flame
  button). It calls `rebook`, and on success a `ManoDialogCard` says "Solicitud
  enviada".

Any other failure shows `failure.message` in a snackbar. An unknown id shows a
`ManoEmptyState` with "No encontramos este trabajo." and "Volver a Actividad"
(`/projects`). A load error shows "No pudimos cargar este trabajo." with
"Reintentar".

## State flow

All of it lives in `packages/mano_session/lib/src/activity/activity_providers.dart`.
It's app-agnostic so PROV-04 and PROV-05 can reuse it.

| Provider | Type | Reads |
|---|---|---|
| `jobProvider(id)` | `FutureProvider.family<Job?, String>` | `JobRepository.job(id)` |
| `jobsByStatusProvider(status)` | `FutureProvider.family<List<Job>, JobStatus>` | filters `myJobsProvider` |
| `requestsByStatusProvider(status)` | `FutureProvider.family<List<ServiceRequest>, ServiceRequestStatus>` | filters `myServiceRequestsProvider` |
| `activityActionsProvider` | `NotifierProvider<ActivityActions, void>` | mutations, below |

`ActivityActions` methods return `Result<_, DataFailure>`. Only a success
invalidates:

| Method | Port call | Invalidates on `Ok` |
|---|---|---|
| `cancelJob(id, {reason})` | `JobRepository.cancel` | `myJobsProvider`, the whole `jobProvider` family |
| `rebook(jobId)` | `JobRepository.rebook` | `myServiceRequestsProvider` |
| `cancelRequest(id)` | `ServiceRequestRepository.cancel` | `myServiceRequestsProvider` |

The selectors watch the base lists, so invalidating `myJobsProvider` or
`myServiceRequestsProvider` refreshes every filter. Screens keep only
presentation state: the selected filter and a busy flag.

## Ports and adapters

- `JobRepository`: `MockJobRepository` (the gateway stubs jobs)
- `ServiceRequestRepository`: `MockServiceRequestRepository`

## Shared widgets

No new `mano_ui` widgets, and no existing widget changed. The module reuses
these:

- `ManoProjectFilterTabs`
- `ManoProjectCard`
- `ManoStatusChip`
- `ManoEmptyState`
- `ManoPromptSheet` / `showManoSheet`
- `ManoDialogCard` / `showManoDialog`
- `ManoPriceTag`
- `ManoAvatar`
- `ManoTextField`
- `ManoPrimaryButton`, `ManoOutlineButton`, `ManoQuietButton`

App-local helpers in `features/activity/`:

- `activity_labels.dart`: status, price and rate copy
- `request_sheet.dart`
- `load_error.dart`

## Removed: `Project`

The tab used to read `Project` / `projectsProvider`. Nothing else referenced
them, so these are deleted along with their tests:

- `Project`, `ProjectStatus`, `ProjectRepository` (domain)
- `MockProjectRepository` (data)
- `projectRepositoryProvider` / `projectsProvider` (session)

## Tests

- `packages/mano_session/test/activity/activity_providers_test.dart`: the
  selectors, `jobProvider`, and each action's result and invalidation.
- `apps/requester/test/screens/projects_tab_screen_test.dart`: filters, card
  mapping, empty states and their CTA, the error state, job navigation, and the
  request cancel sheet.
- `apps/requester/test/features/activity/job_detail_screen_test.dart`: details,
  not found, error, cancel with reason, dismissing the sheet, and rebook.
- `apps/requester/test/features/activity/activity_flow_test.dart`: a host twin
  of the device flow.
- `apps/requester/integration_test/activity_flow_test.dart`: the device flow.
  Signed in: Actividad → Programados → open job-1 → Cancelar → Sí, cancelar →
  back → it shows under Cancelados.

## Backend gaps

- The gateway stubs jobs and service requests (`docs/develop/backend-contract.md`), so
  both repositories are mocks.
- `JobRepository.rebook` creates a request in the job repository's own memory.
  `MockServiceRequestRepository` never sees it, so with mocks a rebooked
  request doesn't show under Solicitudes. It will once one backend owns both,
  or once the mocks share a store.
- `cancel(reason:)` is accepted but the mock drops the reason.
- There's no live push. Both segments refetch on pull-to-refresh
  (`ManoPullToRefresh`: requests and jobs, or projects) and whenever the app
  comes back into view (`refreshOnResumeProvider`); otherwise a provider's
  action shows only after this app invalidates its reads.
- The job detail's app bar has "Escribir" (`JobChatButton`, chat icon): it opens
  the job's conversation (`conversationActionsProvider.open(jobId:)`) and pushes
  `/inbox/<id>`; a guest gets the account sheet.
