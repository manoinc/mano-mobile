# Components

Everything on screen is built from `mano_ui`, a package of presentational
widgets shared by both apps. **Open the [live catalogue](../widgetbook/index.html)**
to see each one in light and dark, at phone size and at large text, with knobs.

!!! info "Why widgets only take strings"
    `mano_ui` can't see the app's data model. A component takes strings,
    booleans, callbacks and `Widget` slots, and the screen does the mapping, such
    as a job's status to a label and a tone. That keeps every component reusable
    in both apps and testable on its own.

## Catalogue

### Actions

| Component | Use it for |
|---|---|
| `ManoPrimaryButton` | The one flame action on a screen. Full width, supports `busy`. |
| `ManoOutlineButton` | A strong secondary action (ink outline). |
| `ManoQuietButton` | A low-emphasis action in clay text. |
| `ManoTextAction` | An inline link-like action ("Iniciar sesión", "Agendar"). |
| `ManoBrandButton` | Third-party sign-in; takes the brand mark as `leading`. |
| `ManoPressScale` | Wraps anything tappable with the press-down feel. |

### Inputs

| Component | Use it for |
|---|---|
| `ManoTextField` | Labelled text input; single or multi-line, helper and error text. |
| `ManoSearchField` / `ManoSearchPill` | A real search input / a tappable pill that opens search. |
| `ManoAddressPill` | The address selector on Home. |
| `ManoToggleRow` | An on/off setting. |
| `ManoCategoryChip` / `ManoCategoryRail` | Category icons, alone or as a scrolling rail. |
| `ManoProjectFilterTabs` | A row of filter pills (statuses, pricing model). |
| `ManoWeekdayPicker` | L M X J V S D toggles. |
| `ManoDateStrip` / `ManoSlotGrid` | Pick a day / pick a time slot (taken slots struck through). |
| `ManoMessageComposer` | Chat input with send button; optional "+" attach and a strip of pending photos. |

### Cards and rows

| Component | Use it for |
|---|---|
| `ManoListingCard` | A photo-led service listing (Home). |
| `ManoOfferCard` | An offer: price, pricing model, zone; optional status and trailing action. |
| `ManoProjectCard` | A job in a list: person, title, date, price, status. |
| `ManoRequestCard` | An incoming request with message and an `actions` slot. |
| `ManoProjectSummaryCard` | A posted project: title, subtitle, status chip, optional trailing label. |
| `ManoLeadCard` | An open project to quote on: title, category and age, budget, cost ("Gratis"). |
| `ManoQuoteCard` | A quote: avatar slot, name, price, message box, status, Elegir and Descartar. |
| `ManoAmountPad` | A big centred amount over a numeric keypad with a "000" key. |
| `ManoBookingCard` | A booking summary. |
| `ManoConversationTile` | An inbox row with unread badge. |
| `ManoPersonRow`, `ManoDetailRow`, `ManoTagList` | People with rating, label/value rows, tag chips. |
| `ManoProfileHeader`, `ManoGreetingHeader` | Profile top, "Hola, …" header. |

### Status and feedback

| Component | Use it for |
|---|---|
| `ManoStatusChip` | A status pill in one of four tones. |
| `ManoPriceTag` | Amount plus rate ("$45.000 /hora"). |
| `ManoNotice` | An inline message (info, warning, error). |
| `ManoEmptyState` | Nothing to show yet, with one call to action, or none when the screen already has it. |
| `ManoAvatar`, `ManoInitialsAvatar` | A photo (optional online dot) or initials. |
| `ManoPageIndicator` | Carousel dots. |

### Overlays

| Component | Use it for |
|---|---|
| `showManoSheet` + `ManoPromptSheet` | A bottom sheet with one decision. |
| `showManoSheet` + `ManoActionSheet` / `ManoOptionRow` | A list of actions; rows can be destructive. |
| `showManoDialog` + `ManoDialogCard` | A centred confirmation. |

### Navigation and layout

| Component | Use it for |
|---|---|
| `ManoBottomNavBar` | Four tabs around a raised centre action. |
| `ManoHeroScaffold` | Full-bleed brand screens with up to two actions. |
| `ManoStepScaffold` + `ManoStepTransition` | Multi-step forms that slide between steps. |
| `ManoRefreshList` | A pull-to-refresh list with dividers and an empty message. |
| `ManoPullToRefresh` | Makes any screen body pullable: a list inside it, or a still empty state. |

### Chat

| Component | Use it for |
|---|---|
| `ManoChatThread` | A whole thread: day separators, pending and failed messages, retry. |
| `ManoChatBubble` | A single message, with optional photos above the text. |
| `ManoImageViewer` | One photo full screen: pinch to zoom, tap or swipe down to close. |
| `ManoChatHeader` | Name, avatar, online dot and verified badge. |

### Brand

`ManoWordmark`, `ManoMonogram`, `ManoArchMotif`, `ManoOpening`. See
[Logo](../brand/logo.md).

Missing something? See [Adding a component](../develop/adding-a-component.md).
