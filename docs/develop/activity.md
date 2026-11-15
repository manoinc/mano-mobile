# Activity filtering architecture

The requester's Actividad tab (`/projects`) shows everything they have going
on: service requests sent to one professional, the jobs those turn into, and
projects published for quotes. It has one filter row and one list. The kind of
an item never shows up as a filter; the type handling lives in the domain and
the session, not in the UI.

## Buckets

`ActivityBucket` (`packages/mano_domain/lib/src/activity/activity_item.dart`):

| Bucket | Pill | Meaning |
|---|---|---|
| `pending` | Pendientes | Waiting on an answer: a request nobody accepted yet, a project collecting quotes. |
| `active` | En curso | Under way: a booked or running job, a project with a chosen quote. |
| `history` | Historial | Over: finished, cancelled or turned down. |

## Mapping

Every status of every entity has its place, matched exhaustively in a `switch`
so a new status fails to compile until it is placed.

| Entity | Status | Bucket |
|---|---|---|
| `ServiceRequest` | `pending` | pending |
| | `accepted` | not listed: accepting creates a `Job`, which stands for it |
| | `rejected`, `cancelled` | history |
| `Job` | `scheduled`, `inProgress` | active |
| | `finished`, `cancelled` | history |
| `Project` | `open` | pending |
| | `awarded` | active |
| | `closed`, `cancelled` | history |

## Order

Each list runs newest first by `ActivityItem.sortedAt`:

| Entity | Timestamp |
|---|---|
| `ServiceRequest` | `createdAt` |
| `Job` | `start` (a job has no creation date) |
| `Project` | `createdAt` |

Ties keep requests, then jobs, then projects, each in repository order. Dart's
`List.sort` is not stable, so `activityIn` breaks ties on the source index.

Because a job sorts by its start, a job booked for next week sits above one
running today in En curso. Once the gateway gives jobs a creation date, sort
on that instead.

## Where each part lives

| Layer | What | File |
|---|---|---|
| Domain | `ActivityItem`, sealed over `RequestActivity`, `JobActivity`, `ProjectActivity` (each wraps the entity, no copied fields); `bucket`, `sortedAt`; `activityIn(bucket, requests:, jobs:, projects:)` | `packages/mano_domain/lib/src/activity/activity_item.dart` |
| Session | `activityProvider(bucket)` waits on `myServiceRequestsProvider`, `myJobsProvider` and `myProjectsProvider`, then calls `activityIn`. If any of the three fails, the bucket fails. | `packages/mano_session/lib/src/activity/activity_providers.dart` |
| UI | `ProjectsTabScreen` holds the selected bucket; `ActivityList` handles loading, error, empty and pull-to-refresh; `ActivityCard` picks the card per item: `ManoProjectCard` for requests and jobs, `ManoProjectSummaryCard` for projects | `apps/requester/lib/screens/projects_tab_screen.dart`, `features/activity/activity_list.dart`, `features/activity/activity_card.dart` |

The screen's only `switch` on kind is in `ActivityCard`, to choose a card and
where a tap goes:

- a job pushes `/projects/job/<id>`;
- a request opens its sheet, where a pending one can be cancelled;
- a project pushes `/projects/project/<id>`.

Pull-to-refresh and Reintentar refetch all three base reads. Actions invalidate
the base reads they change (`ActivityActions`, `ProjectActions`), so every
bucket follows.

## Why one axis

Users ask "what needs me, what is happening, what is done". They don't ask
"which of my things are projects". The tab used to have two levels: Servicios
and Proyectos, then five status pills under Servicios. That made the user pick
a type before a status, and put the same question in two places.

- Thumbtack's Projects tab has one status axis (To-do's, In progress,
  Finished) over different kinds of project:
  [screen 1](https://mobbin.com/screens/3f961c65-4816-445b-abb1-eaf5e81b0ed8),
  [screen 2](https://mobbin.com/screens/7284947e-ed04-41b7-ac46-23cb3ea0c548).
- Airbnb Trips doesn't split by type either: it is upcoming and past.

## Tests

- `packages/mano_domain/test/activity/activity_item_test.dart`: every status's
  bucket, each timestamp, merging, newest first and stable ties.
- `packages/mano_session/test/activity/activity_provider_test.dart`: merging the
  three reads, the order, a failing source, and a cancel moving a request to
  Historial.
- `apps/requester/test/screens/projects_tab_screen_test.dart`: the one filter
  row, each bucket's items and order, the cards, the empty and error states,
  navigation and the request cancel.
