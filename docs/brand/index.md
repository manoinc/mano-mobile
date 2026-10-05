# Brand system

Mano should feel like the apps people already trust with their money and their
homes: **Wise, Nubank, Uber and Airbnb**. Calm surfaces, one clear action and
motion that feels physical.

## Principles

**One hot surface.**
Flame orange marks the single most important action on a screen. Everything
else is ink, clay or quiet.

**Minimal, not empty.**
Remove until it breaks, then add one thing back. White space is how a screen
says what matters.

**Honest states.**
Every screen that loads has a loading, an empty and an error state. Never a
blank screen, never invented data.

**Native first.**
Nothing opens a browser to finish a task. Sign-in, payments and documents
happen inside the app.

**Spanish, from Colombia.**
Copy is written for Colombian users, in plain *tú*. See
[Voice](voice.md).

## Where the brand lives

| What | Source of truth |
|---|---|
| Colours, spacing, corners | `packages/mano_ui/lib/src/theme/mano_theme.dart` |
| Type | `packages/mano_ui/lib/src/theme/mano_typography.dart` |
| Motion | `packages/mano_ui/lib/src/theme/mano_motion.dart` |
| Logo | `tools/brand/*.svg`, generated into Dart by `dart tools/generate_logo_paths.dart` |
| Money and dates | `ManoFormat` in `packages/mano_ui/lib/src/format/mano_format.dart` |

Designers change the brand in these files, through a developer. A screen never
hard-codes a colour, a size or a curve.
