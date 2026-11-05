# Projects and quotes

**Status: approved and built.** See [REQ-06](../modules/REQ-06-projects.md) and
[PROV-07](../modules/PROV-07-projects.md).

A *project* is a job a Solicitante posts so several Proveedores can quote on it.
It sits beside the existing direct-booking flow: you either pick an offer and
book (`ServiceRequest`), or you describe the job and compare prices (`Project`).

What exists today:

- **Data and state:** `ProjectRepository` and `LeadRepository` (`mano_domain`),
  with mock and gateway adapters (`mano_data`). In `mano_session`:
  `myProjectsProvider`, `openProjectsProvider(category)`, `myQuotesProvider`,
  `projectActionsProvider` and `leadActionsProvider`. See
  [Backend contract](../develop/backend-contract.md#projects-and-quotes).
- **Rules on the entities:** `Project.acceptsQuotes`, `canCancel`,
  `canSelect(quote)` and `canDiscard(quote)`, plus `ProjectDraft.problems`, and
  `failure.isAlreadyQuoted` for the one-quote-per-provider refusal.
- **Quotes are free.** Coins change hands only when the chosen worker buys the
  lead to unlock the client's contact (see [PROV-07](../modules/PROV-07-projects.md)).
  Accepting a service request is free too.

## Research (Mobbin)

| App | What we looked at | Borrow | Avoid |
|---|---|---|---|
| Thumbtack | [Projects tab, in progress](https://mobbin.com/flows/c292181e-18e0-4bd0-91d2-46943e814e04), [project detail with interested pros](https://mobbin.com/flows/256ab77a-1191-46b6-8bf8-3bdb4034c433), request steps [details 70%](https://mobbin.com/screens/6be84020-2389-4ea9-ae00-bc1b8096d39a) and [optional photos](https://mobbin.com/screens/bada6ed2-d3d3-4209-b332-354d4e16c6db), [project details sheet](https://mobbin.com/flows/1f2c45f8-1060-47d0-9564-5973ec372cda) | One question per screen with a thin progress bar, and "optional" said plainly with a Skip. A project card that says where it stands ("Esperando cotizaciones", "1 profesional respondió"). Each pro's price and message on one card. | Seasonal to-do upsells; "Find more pros" lists mixed in with real quotes. |
| Airtasker (closest GetNinjas analogue) | [Posting a task](https://mobbin.com/flows/5f8331b5-ace8-40a4-b132-df5e9a63c08a) incl. [budget keypad](https://mobbin.com/screens/8fc12ce2-bda2-4774-ad52-ee2dc31abeb4), [offers on a task](https://mobbin.com/screens/da38f2a7-176c-43ea-a635-409920931031), [offer accepted](https://mobbin.com/screens/07533183-b86e-42d8-9a40-e349b140b21c), [making an offer](https://mobbin.com/flows/954f4d33-fada-45c5-ac96-63e7d487cda9), [browse tasks](https://mobbin.com/flows/706dea1d-161f-468e-8d9e-843d38424df8) | The budget as a big centred amount over a numeric keypad ("you can negotiate later"). A status strip on the detail (ABIERTO · ASIGNADO). An offer list where each row has avatar, price on the right and the message in a quiet box. Browse rows of title, zone, date and price, with "N ofertas". Making an offer as a big amount, then a preview, then submit. | Service-fee maths on the offer, display-font headlines, and a loud blue on every action. |
| Angi | [Home and category start](https://mobbin.com/flows/72ee53da-b2da-4fee-af14-a8c586e049e4), [project ZIP step](https://mobbin.com/flows/bd3e1422-b724-4c28-bd49-afae5b16e72d), [Projects tab](https://mobbin.com/screens/4ea190d7-5a91-424e-ac6c-b5609ef2a510), [Done tab](https://mobbin.com/screens/5aef34f3-a3be-4210-8aa0-cb6ce2ec588f) | A Projects tab split into *En curso* / *Terminados*, with one pill-shaped "Start a project" pinned above the tab bar. The flow starts from a category. | Long multi-question forms on one screen ([cleaning form](https://mobbin.com/screens/a9629789-b83e-4a9d-be93-6a9a43497be1)). |
| Urban Company | [Requirements stepper](https://mobbin.com/screens/685267da-5db1-4bec-a871-6c7ae342a5d4), [booking scheduled](https://mobbin.com/screens/fb6d3586-fbd8-436d-b2a4-fcb700b10f43), [job complete](https://mobbin.com/screens/fcb24d0b-e63e-41ec-b3b9-0682cefd9b7b) | A detail that opens with a status block (icon, one-line state, one-line explanation), then "Detalles" rows. | Fixed-price carts. UC has no open bidding, so it has no quote pattern to borrow. |
| GetNinjas | Not on Mobbin: we searched "GetNinjas pedido de orçamento" and "GetNinjas home services request" on iOS, and "GetNinjas" on web, with no match. | Airtasker covers the same pedido → orçamentos model. | |
| Airbnb | Not researched: the Mobbin call for the listing-creation steps was declined during this session. | Planned borrowing, from the app as it is known: the "Become a host" pattern of one big question per screen with a "Siguiente" bar, and a review page before publishing. | |

## Requester

### Entry points

1. **Create action sheet** (`apps/requester/lib/shell/create_action_sheet.dart`).
   Today every tap answers "Muy pronto". Its CTA becomes **"Publicar proyecto"**,
   and tapping a category opens the flow with that category preselected, which
   skips step 1.
2. **Home**: a quiet row under the search, "¿No sabes a quién contratar?
   Publica un proyecto y recibe cotizaciones", in clay text. It is not a second
   flame button.

### Publish flow: one question per screen (`ManoQuestionStep`)

```
 ←  ━━━━━──────────                  ←  ━━━━━━━━━━──────
                                    
 ¿Qué necesitas?                     Cuéntanos el trabajo
                                     
 ┌──────────┐ ┌──────────┐           Título
 │ Limpieza │ │ Plomería │           ┌──────────────────────────┐
 └──────────┘ └──────────┘           │ Pintar apartamento 70 m² │
 ┌────────────┐ ┌─────────┐          └──────────────────────────┘
 │Electricidad│ │ Pintura │          Descripción
 └────────────┘ └─────────┘          ┌──────────────────────────┐
 ┌────────────┐                      │ Tres habitaciones, sala… │
 │ Jardinería │                      │                          │
 └────────────┘                      └──────────────────────────┘
                                     Entre más detalles, mejores
                                     cotizaciones.
 [        Continuar        ]  flame  [        Continuar        ]
```

```
 ←  ━━━━━━━━━━━━━━──                 ←  ━━━━━━━━━━━━━━━━━━
                       Omitir       
 ¿Cuánto piensas invertir?           Revisa y publica
 Opcional. Los profesionales         
 cotizan igual.                      Pintura                    Editar
                                     Pintar apartamento de 70 m²
          $ 1.800.000                Tres habitaciones, sala…   Editar
                                     Presupuesto  $1.800.000    Editar
   1    2    3                       
   4    5    6                       Gratis. Te avisamos cuando
   7    8    9                       lleguen cotizaciones.
   000  0    ⌫                       
 [        Continuar        ]         [     Publicar proyecto     ]
```

- **Steps:** category → title and description → budget (optional, with
  Omitir) → review. `ProjectDraft` holds the state; `problems` gates each
  Continuar (`unknownCategory` on step 1, `emptyTitle` and `emptyDescription` on
  step 2, `negativeBudget` on step 3).
- **Budget keypad**, after Airtasker: the amount is set big with `ManoFormat`
  COP, and there is a "000" key, because Colombian prices are in the
  thousands.
- **Photos are not asked for:** the backend has no upload yet. A photo step
  slots in after the description once it does.
- **Success:** a full-screen confirmation, "Proyecto publicado · Te avisaremos
  cuando lleguen cotizaciones", then the project's detail. Calls
  `projectActionsProvider.publish`.

### Projects tab: a segment for "Proyectos"

The tab already holds jobs and requests (`ActivityTab`). Add a top segment with
`ManoProjectFilterTabs`: **Servicios · Proyectos**. *Proyectos* lists
`myProjectsProvider`, newest first.

```
 Proyectos
 ( Servicios )( Proyectos )

 ┌─────────────────────────────────────┐
 │ Pintar apartamento de 70 m²         │
 │ Pintura · hace 5 h                  │
 │ ● 3 cotizaciones   desde $1.450.000 │
 └─────────────────────────────────────┘
 ┌─────────────────────────────────────┐
 │ Cambiar tubería del baño            │
 │ Plomería · ayer                     │
 │ ○ Esperando cotizaciones            │
 └─────────────────────────────────────┘
 ┌─────────────────────────────────────┐
 │ Cambiar toda la iluminación a LED   │
 │ ✓ Elegiste a Andrés C. · $580.000   │
 └─────────────────────────────────────┘
          ( + Publicar proyecto )   outlined pill, Angi-style
```

The status line maps `ProjectStatus` and the quotes as follows:

| Case | Line | Tone |
|---|---|---|
| open, no quotes | Esperando cotizaciones | neutral |
| open, N quotes | N cotizaciones · desde $min | accent |
| awarded | Elegiste a {worker} · $amount | positive |
| closed | Cerrado | neutral |
| cancelled | Cancelado | neutral |

### Project detail and quote comparison

```
 ←                                ⋯   (Cancelar proyecto)
 ABIERTO · ELEGIDO · CERRADO          status strip (Airtasker)
 Pintar apartamento de 70 m²
 Pintura · Publicado hace 5 h
 Presupuesto  $1.800.000
 Tres habitaciones, sala-comedor…  Ver más

 Cotizaciones (3)          Menor precio ▾
 ┌─────────────────────────────────────┐
 │ (JP) Jorge Peña          $1.450.000 │
 │ hace 1 h                            │
 └─────────────────────────────────────┘
 ┌─────────────────────────────────────┐
 │ (AC) Andrés Castro       $1.650.000 │
 │ ┌─────────────────────────────────┐ │
 │ │ Incluye resanar grietas, tratar │ │
 │ │ la humedad y dos manos…         │ │
 │ └─────────────────────────────────┘ │
 │ Descartar                    Elegir │
 └─────────────────────────────────────┘
```

- **Cards:** the quotes sort by price, cheapest first (the sort toggles to "Más
  recientes"). Each card has the avatar, name and price on the right, and the
  message in a sand box (Airtasker).
- **Actions:** `canSelect` and `canDiscard` decide which actions appear. "Elegir"
  is a text action, not a flame, because several cards show at once. Elegir
  then opens a confirm sheet, "¿Elegir a Andrés por $1.650.000? Los demás
  quedan en espera", whose single flame button is "Elegir cotización".
- **The selected quote** pins to the top with a positive chip, "Elegida".
  Discarded quotes collapse under "Descartadas (1)".
- **The ⋯ menu** shows "Cancelar proyecto" only when `canCancel`, behind a
  `ManoDialog`.
- **Placeholder names:** profiles are still placeholders, with an empty
  `displayName`. Until the backend fills them, the card shows "Profesional" and
  initials from the id. This is called out in the backend contract.

## Provider

### Home: "Proyectos abiertos" beside "Solicitudes"

Inicio gets a two-way segment at the top of its list: **Solicitudes ·
Proyectos**. *Proyectos* lists `openProjectsProvider(category)`, with a
category chip rail filtered to the provider's own categories.

```
 Hola, Andrés
 ( Solicitudes )( Proyectos )
 [Todas] [Pintura] [Plomería] …

 ┌─────────────────────────────────────┐
 │ Pintar apartamento de 70 m²         │
 │ Pintura · hace 5 h                  │
 │ Presupuesto $1.800.000   Gratis     │
 └─────────────────────────────────────┘
 ┌─────────────────────────────────────┐
 │ Instalar calentador de paso a gas   │
 │ Plomería · ayer                     │
 │ Sin presupuesto          Gratis     │
 └─────────────────────────────────────┘
```

"Gratis" sits where the coin cost sits on Solicitudes, so a provider learns
that quoting costs nothing yet. The client is hidden until a lead is purchased,
so the card shows no client name or photo.

### Project detail and quote sheet

```
 ←
 Pintar apartamento de 70 m²
 Pintura · Publicado hace 5 h
 Presupuesto del cliente  $1.800.000
 Tres habitaciones, sala-comedor y el
 pasillo. Las paredes tienen grietas…

 [         Cotizar gratis         ]   flame

 ── sheet ──────────────────────────
 Tu cotización
            $ 1.650.000
   1  2  3 / 4  5  6 / 7  8  9 / 000 0 ⌫
 Mensaje (opcional)
 ┌───────────────────────────────────┐
 │ Incluye materiales y…             │
 └───────────────────────────────────┘
 [        Enviar cotización        ]
```

- **The sheet** reuses the budget keypad (Airtasker's "Make an offer"). Sending
  calls `leadActionsProvider.submitQuote`.
- **If the provider already quoted:** a failure where `isAlreadyQuoted` is true
  reads "Ya cotizaste este proyecto". The detail then shows "Ya cotizaste ·
  $1.650.000" in place of the flame, so the button is never offered twice.
- **If the project closed meanwhile:** a `FailedPrecondition` reads "Este
  proyecto ya no recibe cotizaciones".

### "Mis cotizaciones"

A third segment on Inicio, or a row in Perfil. The proposal is the segment,
**Solicitudes · Proyectos · Mis cotizaciones**, because quotes are part of the
daily work, not settings.

```
 ┌─────────────────────────────────────┐
 │ Pintar apartamento de 70 m²         │
 │ Tu cotización $1.650.000  ○ Enviada │
 └─────────────────────────────────────┘
 ┌─────────────────────────────────────┐
 │ Cambiar toda la iluminación a LED   │
 │ Tu cotización $580.000   ● Elegida  │
 └─────────────────────────────────────┘
```

`QuoteStatus` maps to these labels: submitted → Enviada (neutral), selected →
Elegida (positive), discarded → No elegida (neutral). An "Elegida" quote
reads "El cliente te eligió. Compra su contacto por N coins"; once bought, its
detail shows the client's phone and email.

## Widgets (`mano_ui`)

| Need | Widget | Note |
|---|---|---|
| Publish steps | `ManoQuestionStep` / `ManoStepScaffold`, `ManoStepTransition` | existing |
| Category step | `ManoCategoryChip` | existing |
| Title and description | `ManoTextField` | existing |
| Segments | `ManoProjectFilterTabs` | existing, already string-only |
| Status chips | `ManoStatusChip` / `ManoStatusTone` | existing |
| Prices | `ManoPriceTag` | existing |
| Empty lists | `ManoEmptyState` | existing |
| Confirm and cancel | `ManoSheet`, `ManoDialog` | existing |
| My-projects card | **`ManoProjectCard`**, adapted | It is shaped for a booked job (professional, schedule). Make `professionalName`, `professionalPhotoUrl` and `scheduledLabel` optional, and add `subtitle`, or add a sibling. Proposal: add a new `ManoProjectSummaryCard` (title, subtitle, statusLabel, statusTone, trailingLabel, onTap) to keep the old card's tests intact. |
| Open-lead card | **`ManoLeadCard`** (new) | title, categoryLabel, ageLabel, budgetLabel, costLabel ("Gratis"), onTap. Compare `ManoRequestCard`: it requires a client, which projects hide. |
| Quote row | **`ManoQuoteCard`** (new) | avatar `Widget` slot, name, amountLabel, message, statusLabel/tone, `onSelect`/`onDiscard` nullable (null hides the action), selected bool |
| Amount entry | **`ManoAmountPad`** (new) | amountLabel, onDigit, onBackspace, helper text. Shared by budget and quote. |

Each new widget is dumb (strings, bools and callbacks only), uses tokens only,
and gets a Widgetbook use case.

## Brand checks

- **One flame per screen:** Continuar, Publicar proyecto, Cotizar gratis,
  Enviar cotización, and the confirm "Elegir cotización". Elegir and
  Descartar on cards are text actions. On Actividad › Proyectos the shell's
  centre "+" is the flame, so the "+ Publicar proyecto" pill is outlined.
- **Corners:** `ManoRadius.card` on cards and boxes, `ManoRadius.pill` on chips,
  segments and the floating pill. Nothing else.
- **Type and colour:** Poppins through the text theme. Clay for links, sand for
  message boxes, stone for dividers.
- **Motion:** step changes use `ManoMotion.entrance` via `ManoStepTransition`.
- **Copy:** Spanish, *tú*, short.

## Decisions

The open questions were answered on approval:

1. **Requester:** projects are a segment in the Actividad tab, "Servicios ·
   Proyectos" (`ManoProjectFilterTabs`), with a compact "+ Publicar
   proyecto" pill floating over the list. The create sheet's CTA is
   "Publicar proyecto" (a category tap preselects it), and Home has a quiet
   clay row.
5. **The Proyectos pill is outlined, not flame** (decided after the first
   device run, Oct 2026). The shell's centre "+" is already the flame on every
   tab, and a flame pill (or the empty state's full-width button) made two.
   The pill is ink-outlined on the surface, compact, and the same with or
   without projects; the empty state shows no button of its own.
2. **Provider:** "Mis cotizaciones" is a third segment on Inicio: Solicitudes ·
   Proyectos · Mis cotizaciones.
3. **"Gratis"** shows explicitly in the cost slot of open-project cards.
4. **A new `ManoProjectSummaryCard`**; `ManoProjectCard` and its tests stay
   untouched.
