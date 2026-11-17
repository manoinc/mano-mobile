# REQ-04 Activity (requester)

The requester's "Actividad" tab and the job detail screen: what they asked
for, what's booked, what's happening now, and what is over.

## Screens and routes

| Route | Class | File |
|---|---|---|
| `/projects` | `ProjectsTabScreen` → `ActivityList` | `apps/requester/lib/screens/projects_tab_screen.dart`, `features/activity/activity_list.dart` |
| `/projects/job/:id` | `JobDetailScreen(jobId:)` | `features/activity/job_detail_screen.dart` |

### Actividad tab

"Tu actividad", then one `ManoProjectFilterTabs` row (Pendientes · En curso ·
Historial) over one list. Each list mixes requests, jobs and
[projects](REQ-06-projects.md), newest first. How items land in each bucket,
and why there is no Servicios/Proyectos split:
[Activity filtering architecture](../develop/activity.md).

| Filter | Requests | Jobs | Projects |
|---|---|---|---|
| Pendientes (default) | `pending` | none | `open` |
| En curso | none | `scheduled`, `inProgress` | `awarded` |
| Historial | `rejected`, `cancelled` | `finished`, `cancelled` | `closed`, `cancelled` |

Accepted requests aren't listed, because accepting one creates a job.

`ActivityCard` draws each item with the card its kind already has:

- **Requests and jobs** use `ManoProjectCard`: the service title, the
  provider's name and photo, a date (`ManoFormat.dateTime`; for requests the
  proposed start, or the creation date if there is none), the price
  (`ManoFormat.cop`, plus `/hora` for hourly) and a `ManoStatusChip`. They are
  keyed `activity-job-<id>` and `activity-request-<id>`.
- **Projects** use `ManoProjectSummaryCard`, keyed `project-card-<id>`
  ([REQ-06](REQ-06-projects.md)).

Taps:

- Tapping a **job** pushes `/projects/job/<id>`.
- Tapping a **project** pushes `/projects/project/<id>`.
- Tapping a **request** opens a `ManoPromptSheet` showing the provider, the
  proposed date, the message and any rejection reason. A pending request's
  sheet offers "Cancelar solicitud". On success a snackbar says "Cancelamos tu
  solicitud." and the card moves to Historial. Closed requests only offer
  "Entendido".

The list's other states:

- Each filter has its own `ManoEmptyState` message, with no CTA. The outlined
  "+ Publicar proyecto" pill floats over every filter, and the shell's centre
  "+" stays the one flame.
- Loading shows a spinner. Errors show "No pudimos cargar tu actividad." with
  "Reintentar", which invalidates all three list reads. If any one of the three
  fails, the whole list shows this error.

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
- `job.canRebook` shows **"Volver a contratar"**. It calls `rebook`, and on
  success a `ManoDialogCard` says "Solicitud enviada". On a cancelled job it is
  the flame button. On a finished job **"Calificar"** leads and rebooking is
  the outline button below it, until the job is rated
  ([REVIEWS-01](REVIEWS-01-rating-flows.md)).

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
| `activityProvider(bucket)` | `FutureProvider.family<List<ActivityItem>, ActivityBucket>` | merges `myServiceRequestsProvider`, `myJobsProvider`, `myProjectsProvider` through `activityIn` |
| `jobsByStatusProvider(status)` | `FutureProvider.family<List<Job>, JobStatus>` | filters `myJobsProvider` (provider app) |
| `requestsByStatusProvider(status)` | `FutureProvider.family<List<ServiceRequest>, ServiceRequestStatus>` | filters `myServiceRequestsProvider` (provider app) |
| `activityActionsProvider` | `NotifierProvider<ActivityActions, void>` | mutations, below |

`ActivityActions` methods return `Result<_, DataFailure>`. Only a success
invalidates:

| Method | Port call | Invalidates on `Ok` |
|---|---|---|
| `cancelJob(id, {reason})` | `JobRepository.cancel` | `myJobsProvider`, the whole `jobProvider` family |
| `rebook(jobId)` | `JobRepository.rebook` | `myServiceRequestsProvider` |
| `cancelRequest(id)` | `ServiceRequestRepository.cancel` | `myServiceRequestsProvider` |

The selectors watch the base lists, so invalidating `myJobsProvider`,
`myServiceRequestsProvider` or `myProjectsProvider` refreshes every filter.
Screens keep only presentation state: the selected filter and a busy flag.

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

- `activity_list.dart`: the list's states and pull-to-refresh
- `activity_card.dart`: the card per kind, and the request cancel
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

- `packages/mano_domain/test/activity/activity_item_test.dart`: each status's
  bucket, the timestamps, and the newest-first merge.
- `packages/mano_session/test/activity/activity_providers_test.dart`: the
  selectors, `jobProvider`, and each action's result and invalidation.
- `packages/mano_session/test/activity/activity_provider_test.dart`: the merged
  buckets, their order, and a failing source.
- `apps/requester/test/screens/projects_tab_screen_test.dart`: the filter row,
  each bucket's items and order, card mapping, empty states, the error state,
  job and project navigation, and the request cancel sheet.
- `apps/requester/test/features/projects/publish_project_pill_test.dart`: the
  floating pill on every filter.
- `apps/requester/test/features/activity/job_detail_screen_test.dart`: details,
  not found, error, cancel with reason, dismissing the sheet, and rebook.
- `apps/requester/test/features/activity/activity_flow_test.dart`: a host twin
  of the device flow.
- `apps/requester/integration_test/activity_flow_test.dart`: the device flow.
  Signed in: Actividad → En curso → open job-1 → Cancelar → Sí, cancelar →
  back → it shows under Historial.

## Backend gaps

- The gateway stubs jobs and service requests (`docs/develop/backend-contract.md`), so
  both repositories are mocks.
- `JobRepository.rebook` creates a request in the job repository's own memory.
  `MockServiceRequestRepository` never sees it, so with mocks a rebooked
  request doesn't show under Pendientes. It will once one backend owns both,
  or once the mocks share a store.
- `cancel(reason:)` is accepted but the mock drops the reason.
- There's no live push. The list refetches on pull-to-refresh
  (`ManoPullToRefresh`: requests, jobs and projects) and whenever the app
  comes back into view (`refreshOnResumeProvider`); otherwise a provider's
  action shows only after this app invalidates its reads.
- The job detail's app bar has "Escribir" (`JobChatButton`, chat icon): it opens
  the job's conversation (`conversationActionsProvider.open(jobId:)`) and pushes
  `/inbox/<id>`; a guest gets the account sheet.
