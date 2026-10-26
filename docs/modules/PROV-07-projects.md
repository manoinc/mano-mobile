# PROV-07 Open Projects & Quotes (provider)

Professionals browse open projects and send one free quote each. Design and
research: [Projects and quotes](../design/projects-and-quotes.md).

## Screens and routes

| Route | Class | File |
|---|---|---|
| `/home` | `HomeSegments`: Solicitudes · Proyectos · Mis cotizaciones | `features/home/home_segments.dart` |
| `/home/project/:id` | `LeadDetailScreen(projectId:)` | `features/projects/lead_detail_screen.dart` |

### Proyectos segment

`OpenProjectsSection`: a `ManoProjectFilterTabs` rail ("Todas" plus
`providerCategoriesProvider`, the categories of the professional's own offers),
over `openProjectsProvider(category)` as `ManoLeadCard`s keyed
`lead-card-<id>`. The cost slot says "Gratis". The client stays hidden.

Empty: "No hay proyectos abiertos por ahora." (or "…en esta categoría.") with
"Ver mis servicios". Error: "No pudimos cargar los proyectos."

### Mis cotizaciones segment

`MyQuotesSection`: `myQuotesProvider` as `ManoProjectSummaryCard`s keyed
`my-quote-<id>`. The chip is `QuoteCopy.statusLabel` (Enviada, Elegida, No
elegida). The subtitle is "Tu cotización $X", or "El cliente te elegió. Pronto
podrás contactarlo." once selected. Empty: "Aún no has enviado cotizaciones."
with "Ver proyectos", which switches segment.

### Project detail

The title, category and age, "Presupuesto del cliente", and the description.
The bottom slot is one of:

- **"Ya cotizaste · $X"** when `myQuotesProvider` holds a quote for it;
- **"Cotizar gratis"** (flame) while `acceptsQuotes`. It asks guests to sign in,
  then opens the quote sheet: `ManoAmountPad`, an optional message, and
  "Enviar cotización", which calls `leadActionsProvider.submitQuote`.

Snackbars: "Cotización enviada"; "Ya cotizaste este proyecto" when
`isAlreadyQuoted` (and `myQuotesProvider` is refetched); "Este proyecto ya no
recibe cotizaciones" when `isClosedForQuotes` (a `FailedPrecondition`). A
project no longer on the board shows "Este proyecto ya no recibe
cotizaciones." with "Volver a Inicio".

## State

`openProjectsProvider`, `myQuotesProvider`, `leadActionsProvider` and
`providerCategoriesProvider` in `packages/mano_session/lib/src/projects/`.

## Tests

- `apps/provider/test/features/projects/`: the segments, the detail and quote
  sheet, and `projects_flow_test.dart` (the host twin). They stand
  `FakeServiceCatalog` in for the always-live catalog that
  `providerCategoriesProvider` reads.
- `apps/provider/integration_test/projects_flow_test.dart`: quote on
  project-5, then find it under Mis cotizaciones.

## Backend gaps

- Lead purchase is a stub, so quoting costs no Mano coins.
- A selected quote can't show the client's contact yet.
