# Patterns

How components combine into screens. Follow these and a new screen will feel like
the rest of the app.

## Screen anatomy

```
┌──────────────────────────────┐
│ ← Title                      │  back + headlineMedium title
│                              │
│  Content                     │  16 gutters, 24 between sections
│  (cards, lists, fields)      │
│                              │
│  Quiet secondary action      │  clay text / ink outline
│ ┌──────────────────────────┐ │
│ │      Primary action       │ │  ManoPrimaryButton, flame, bottom
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

- **At most one flame button.** In lists, per-item actions are quiet or ink
  outlines.
- **Title says where you are;** the button says what happens next.

## Every async screen has three states

| State | Show |
|---|---|
| Loading | A centred spinner (or skeleton, later) |
| Empty | `ManoEmptyState` with one way forward ("Publicar mi primer servicio") |
| Error | A plain sentence plus *Reintentar* |

Never leave a blank screen, and never show sample data as if it were real.

## Lists and filters

- Filters are `ManoProjectFilterTabs` above the list. The first tab is the most
  common view.
- Group by day with small headers ("Hoy", "Mañana", "jue 8 oct") when time matters.
- A tap on a card opens its detail; actions on the card are for the one or two
  things people do most (Aceptar / Rechazar).

## Decisions: sheets versus dialogs

| Use | When |
|---|---|
| **Sheet** (`showManoSheet`) | A decision tied to what's on screen, or one that needs input (a reason, a number of hours). |
| **Dialog** (`showManoDialog`) | A short, destructive confirmation ("¿Eliminar esta oferta?"). |

Destructive confirmations name the consequence: "Sí, cancelar", not "OK".

## Forms and steps

- One topic per step (`ManoStepScaffold`), sliding forwards and back with
  `ManoStepTransition`.
- Validate on *Continuar*, then live as the person types.
- Keep entered data when something fails; show the problem in a `ManoNotice`.

## Feedback after an action

- A short snackbar that says what happened and, if useful, offers the next step
  ("Solicitud aceptada · quedó en tu agenda" + *Ver agenda*).
- Opening a sheet clears any snackbar, so it can never cover the sheet's buttons.

## Guests

Browsing never requires an account. Ask for sign-in only when an action needs
one, at the moment it's needed: "Necesitas una cuenta" + *Iniciar sesión*.
