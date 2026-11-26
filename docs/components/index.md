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
| `ManoPrimaryButton` | The one flame action on a screen. Full width, supports `busy`. `tone: ink` fills it with ink for a main action that is not the hot one, as "Agregar método de pago". |
| `ManoOutlineButton` | A strong secondary action (ink outline). `tone: flame` pairs it with a flame primary; an optional `leading` widget (`ManoEnvelopeIcon` on "Crear cuenta con correo"). |
| `ManoWelcomeActions` | The welcome's two equal flame pills side by side ("Iniciar sesión", "Registrarse"), with a full-width slot below for the platform button. The one-flame rule's only exception, see [Colour](../brand/colour.md). |
| `ManoQuietButton` | A low-emphasis action in clay text. |
| `ManoTextAction` | An inline link-like action ("Iniciar sesión", "Agendar"). |
| `ManoBrandButton` | Third-party sign-in; takes the brand mark as `leading`. |
| `ManoPlatformSignInButton` | "Continuar con Apple" on iOS, "Continuar con Google" elsewhere. White pill with the official mark: Google and Apple forbid recolouring them. |
| `ManoBrandPillRow` | Equal-width outlined pills holding only brand marks ("O continúa con"); each pill's label is its tooltip and screen-reader text. |
| `ManoPressScale` | Wraps anything tappable with the press-down feel. |

### Inputs

| Component | Use it for |
|---|---|
| `ManoTextField` | Labelled text input; single or multi-line, helper and error text. |
| `ManoLabelledField` | A label above an outlined 14px box: a text input, or `.select` showing a value with a chevron that opens a picker. |
| `ManoPhoneField` | "País o región" select (flag, name, dial code) above "Número de celular", both `ManoLabelledField`s. |
| `ManoOtpField` | Six code boxes over one hidden field: SMS autofill (`oneTimeCode`), paste, error text. |
| `ManoResendTimer` | "Reenviar código" held back by a countdown, restarted on each resend. |
| `ManoSearchField` / `ManoSearchPill` | A real search input / a tappable pill that opens search. |
| `ManoAddressPill` | The address selector on Home. |
| `ManoToggleRow` | An on/off setting. |
| `ManoCategoryChip` / `ManoCategoryRail` | Category icons, alone or as a scrolling rail. |
| `ManoCategoryTile` | A category in a browse grid: square photo (an app asset passed as `image`) beside a bold label of up to three lines. Search uses two columns of them. |
| `ManoProjectFilterTabs` | A row of filter pills (statuses, pricing model). |
| `ManoWeekdayPicker` | L M X J V S D toggles. |
| `ManoDateStrip` / `ManoSlotGrid` | Pick a day / pick a time slot (taken slots struck through). |
| `ManoMessageComposer` | Chat input with send button; optional "+" attach and a strip of pending photos. |
| `ManoMessageComposer` | Chat input with send button. |
| `ManoChoiceChip` | A pill to pick (skills, a ticket kind) or, with `onRemove`, to take away (zones). |
| `ManoSupportForm` | A PQRS request: kind pills, subject and description; the screen sends it. Shared by both apps. |

### Cards and rows

| Component | Use it for |
|---|---|
| `ManoListingCard` | A photo-led service listing (Home). |
| `ManoOfferCard` | An offer: price, pricing model, zone; optional status, trailing action, rating badge and provider tap. |
| `ManoProjectCard` | A job in a list: person, title, date, price, status. |
| `ManoRequestCard` | An incoming request with message and an `actions` slot. |
| `ManoProjectSummaryCard` | A posted project: title, subtitle, status chip, optional trailing label. |
| `ManoLeadCard` | An open project to quote on: title, category and age, budget, cost ("Gratis"). |
| `ManoQuoteCard` | A quote: avatar slot, name, price, message box, status, Elegir and Descartar; optional rating badge and provider tap. |
| `ManoAmountPad` | A big centred amount over a numeric keypad with a "000" key. |
| `ManoBookingCard` | A booking summary. |
| `ManoConversationTile` | An inbox row with unread badge. |
| `ManoPersonRow`, `ManoDetailRow`, `ManoTagList` | People with rating, label/value rows, tag chips. |
| `ManoPriceBreakdown` | Airbnb-style price details: labelled lines, a rule, the total. Used by the job checkout. |
| `ManoMethodOption` | One way to pay, picked like a radio; a null `onTap` shows it disabled with a `tag` such as "Próximamente". |
| `ManoPaymentLogo` | A payment brand's logo in one 48 × 24 box, scaled down whole and left-aligned, so method rows line up. The app passes its own `Image.asset` from `assets/payments/`; `fallback` covers a method without a logo. |
| `ManoMethodRow` | A saved payment method: mark, name, detail, optional tag, and a small outlined action ("Editar"). |
| `ManoInfoCard` | An outlined reassurance card: icon, title, message and an optional link ("Paga siempre a través de Mano"). |
| `ManoProfileHeader`, `ManoGreetingHeader` | Profile top with an optional contact line, "Hola, …" header. |
| `ManoStatTile`, `ManoReferralCard` | One standing figure; the invite-a-colleague card, with coin and progress only when a reward runs. |

### Status and feedback

| Component | Use it for |
|---|---|
| `ManoStatusChip` | A status pill in one of four tones. |
| `ManoPriceTag` | Amount plus rate ("$45.000 /hora"). |
| `ManoRatingBadge` | A provider's stars on one line ("★ 4,9 · 32"), or "Nuevo" without a star. |
| `ManoNotice` | An inline message (info, warning, error). |
| `ManoEmptyState` | Nothing to show yet, with one call to action, or none when the screen already has it. |
| `ManoAvatar`, `ManoInitialsAvatar` | A photo (optional online dot, or a local `image`) or initials. |
| `ManoAvatarEditor` | The user's own photo with a camera badge and an uploading spinner. |
| `ManoSupportForm` | "Escribir a soporte": Asunto and Cuéntanos qué pasó, with Enviar. Both apps. |
| `ManoPageIndicator` | Carousel dots. |

### Overlays

| Component | Use it for |
|---|---|
| `showManoSheet` + `ManoPromptSheet` | A bottom sheet with one decision; `secondaryLabel` adds a quiet way to decline ("Ahora no"). |
| `showManoSheet` + `ManoCountryPickerSheet` | A searchable country list (flag, name, dial code, a check on the chosen one); search ignores case and accents and matches dial codes. |
| `showManoSheet` + `ManoActionSheet` / `ManoOptionRow` | A list of actions; rows can be destructive or carry a `tag` ("Predeterminada"). |
| `showManoDialog` + `ManoDialogCard` | A centred confirmation. |

### Navigation and layout

| Component | Use it for |
|---|---|
| `ManoBottomNavBar` | Four tabs around a raised centre action. |
| `ManoHeroScaffold` | Full-bleed brand screens: wordmark, headline, an `actions` slot (usually `ManoWelcomeActions`), footnote. |
| `ManoIllustratedStep` | A step led by a full-bleed picture (an app asset, passed as a slot): one highlighted line, Tomar foto, an optional quiet action. |
| `ManoSignInLayout` | Wise's log-in: round close, bold title, fields, the flame "Continuar", an underlined link, and a footer pinned to the bottom under a grey label (hidden while the keyboard is up). |
| `ManoPhoneSignInScreen` | The one sign-in screen both apps show: country and number, then the code. Dumb; each app maps `phoneSignInProvider` onto it. |
| `ManoStepScaffold` + `ManoStepTransition` | Multi-step forms that slide between steps; `headlineEmphasis` paints part of the headline in flame. |
| `ManoEmphasisText` | One sentence with one fragment set apart (flame by default). |
| `ManoTipList` | Bulleted advice in quiet text, each with a bold fragment (`ManoTip`). |
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

`ManoEnvelopeIcon` is Heroicons' outline envelope (v2.2.0, MIT), drawn as a
path so `mano_ui` still ships no images. It marks every email alternative:
the "Continuar con correo" pill and "Crear cuenta con correo". It takes the
ambient `IconTheme` size and colour.

Loading is a skeleton, not the logo: `ManoSkeletonList()` for a screen or
section, `ManoSkeleton` / `ManoSkeleton.circle` for a bespoke layout. They pulse
softly and sit still under reduced motion. Inline spots (a button, a photo
tile) use a small `CircularProgressIndicator`. The animated `m` is only the
splash (`ManoOpening`).

Missing something? See [Adding a component](../develop/adding-a-component.md).
