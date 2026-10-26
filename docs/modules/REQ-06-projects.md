# REQ-06 Projects & Quotes (requester)

The requester describes a job once and compares the quotes professionals send.
Design and research: [Projects and quotes](../design/projects-and-quotes.md).

## Screens and routes

| Route | Class | File |
|---|---|---|
| `/publish?category=` (root navigator) | `PublishProjectScreen(initialCategory:)` | `features/projects/publish/publish_project_screen.dart` |
| `/projects?segment=proyectos` | `ProjectsTabScreen(showProjects:)` → `MyProjectsList` | `screens/projects_tab_screen.dart`, `features/projects/my_projects_list.dart` |
| `/projects/project/:id` | `ProjectDetailScreen(projectId:)` | `features/projects/project_detail_screen.dart` |

### Entry points

All three go through `startPublishing`, which asks a guest to sign in first
(`account_gate.dart`):

- the create sheet (`shell/create_action_sheet.dart`): "Publicar proyecto", or a
  category, which skips step 1;
- the Proyectos segment's outlined pill "+ Publicar proyecto" (the shell's
  centre "+" is the flame);
- a quiet clay row on Home (`PublishProjectRow`).

### Publish flow

One `ManoQuestionStep` per screen, moved by `ManoStepTransition`:

1. **Category**: `ManoCategoryChip`s; Continuar waits for `unknownCategory` to clear.
2. **Title and description**: `ManoTextField`s; Continuar waits for the title
   and description problems to clear.
3. **Budget**: optional, on `ManoAmountPad` (`typeAmount` / `eraseAmount`);
   Omitir clears it.
4. **Review**: each part has Editar; "Publicar proyecto" calls
   `projectActionsProvider.publish`. A failure shows its message in a snackbar.

Success shows "Proyecto publicado"; "Ver proyecto" goes to
`/projects/project/<id>?segment=proyectos`.

### Proyectos segment

`myProjectsProvider` as `ManoProjectSummaryCard`s, keyed `project-card-<id>`.
`projectStatusLine` maps each project:

| Case | Chip | Trailing |
|---|---|---|
| open, no live quotes | Esperando cotizaciones | none |
| open, N live quotes | N cotizaciones | desde $min |
| awarded | Elegiste a {worker} | $amount |
| closed / cancelled | Cerrado / Cancelado | none |

Empty: `ManoEmptyState` "Aún no has publicado proyectos." with "Publicar
proyecto". Error: "No pudimos cargar tus proyectos." with Reintentar.

### Project detail

A status strip (ABIERTO · ELEGIDO · CERRADO, or a Cancelado chip), the title,
category and age, budget and description, then `ProjectQuotesSection`:

- `arrangeQuotes` pins the selected quote with an "Elegida" chip, sorts the rest
  by price ("Menor precio") or recency ("Más recientes"), and folds discarded
  ones under "Descartadas (n)".
- `ManoQuoteCard`, keyed `quote-<id>`. Elegir and Descartar show only when
  `canSelect` / `canDiscard` allow. Elegir opens a confirm sheet, "¿Elegir a
  {name} por {amount}?", whose one flame button is "Elegir cotización".
- The ⋯ menu ("Más opciones") shows only when `canCancel`; "Cancelar proyecto"
  asks in a `ManoDialogCard` ("Sí, cancelar").
- Selecting, discarding and cancelling need an account.

Unknown id: "No encontramos este proyecto." Error: "No pudimos cargar este
proyecto."

## State

All in `packages/mano_session/lib/src/projects/`: `myProjectsProvider`,
`projectActionsProvider`, plus the helpers `arrangeQuotes`, `ProjectQuotes`
(`liveQuotes`, `lowestQuoteCop`, `selectedQuote`), `QuoteCopy` (`workerName`,
`workerInitials`, `statusLabel`) and `typeAmount` / `eraseAmount`.

## Tests

- `apps/requester/test/features/projects/`: the publish flow, the segment list,
  the detail, the entry points, and `projects_flow_test.dart` (the host twin).
- `apps/requester/integration_test/projects_flow_test.dart`: publish from the
  create sheet, then choose a quote on project-1.

## Backend gaps

- Profiles have empty names, so quotes read "Profesional" with initials and a
  tint from the worker id.
- No photo upload yet, so the flow asks for none.
- Quotes arrive only when the list is refetched; there is no live update.
