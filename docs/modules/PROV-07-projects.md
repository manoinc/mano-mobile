# PROV-07 Open Projects & Quotes (provider)

Professionals browse open projects and send one free quote each. The worker
the client picks buys the lead in Mano coins to unlock the client's contact.
Design and research: [Projects and quotes](../design/projects-and-quotes.md).

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
elegida). The subtitle is "Tu cotización $X"; once selected, "El cliente te
eligió. Compra su contacto por N coins." (`leadPricesProvider`); once bought,
"Contacto desbloqueado. Escríbele al cliente." Empty: "Aún no has enviado
cotizaciones." with "Ver proyectos", which switches segment.

Tapping a selected, unbought quote opens the **lead purchase sheet**
(`lead_purchase_sheet.dart`): "Costo", "Tu saldo" and "Comprar · N coins",
which calls `leadActionsProvider.purchaseLead` and refreshes the wallet.
Success shows "Contacto desbloqueado". `InsufficientCoins` opens "Te faltan N
coins" (`insufficient_coins_sheet.dart`), whose "Recargar" opens the recharge
sheet; any other failure shows its message. Every other quote opens the
project detail.

### Project detail

An open project shows the title, category and age, "Presupuesto del cliente", the description, and the
client's photos (`ManoPhotoGallery`, tap to open) when there are any.
The bottom slot is one of:

- **"Ya cotizaste · $X"** when `myQuotesProvider` holds a quote for it;
- **"Cotizar gratis"** (flame) while `acceptsQuotes`. It asks guests to sign in,
  then opens the quote sheet: `ManoAmountPad`, an optional message, and
  "Enviar cotización", which calls `leadActionsProvider.submitQuote`.

Snackbars: "Cotización enviada"; "Ya cotizaste este proyecto" when
`isAlreadyQuoted` (and `myQuotesProvider` is refetched); "Este proyecto ya no
recibe cotizaciones" when `isClosedForQuotes` (a `FailedPrecondition`).

An awarded project leaves the open board, so the detail falls back to the
provider's quote: the title, category and "Tu cotización $X". While the lead
is unbought the bottom slot is "Comprar contacto" (the purchase sheet). Once
bought, `ClientContactSection` lists the client's phone and email
(`ManoIntegrationRow`s): "Llamar" (`tel:`), WhatsApp "Abrir" (`wa.me`, +57
added to a local mobile) and "Escribir" (`mailto:`), built by
`phoneCallUri`, `whatsAppUri` and `emailUri` in mano_session and opened
through `externalLinkOpenerProvider`. A project neither open nor quoted shows
"Este proyecto ya no recibe cotizaciones." with "Volver a Inicio".

## State

`openProjectsProvider`, `myQuotesProvider`, `leadActionsProvider` and
`providerCategoriesProvider` in `packages/mano_session/lib/src/projects/`;
`leadPricesProvider` and `walletProvider` in `src/wallet/`.

## Tests

- `apps/provider/test/features/projects/`: the segments, the detail and quote
  sheet, and `projects_flow_test.dart` (the host twin). They stand
  `FakeServiceCatalog` in for the always-live catalog that
  `providerCategoriesProvider` reads.
- `apps/provider/integration_test/projects_flow_test.dart`: quote on
  project-5, then find it under Mis cotizaciones.

## Backend gaps

- Lead purchase and `Quote.clientContact` need mano-gateway's
  `purchaseProjectLead` and `leadPrices` (mano-gateway #7) deployed.
- A repeat purchase: the gateway answers the same lead without charging; the
  offline mock refuses it.
