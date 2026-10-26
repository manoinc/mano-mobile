# Spacing, corners and layout

## Spacing

A 4-point scale. Every gap comes from it, so screens built months apart still
line up.

| Token | Value | Typical use |
|---|---|---|
| `ManoSpacing.xs` | 4 | Icon to label, chip padding |
| `ManoSpacing.sm` | 8 | Between related items |
| `ManoSpacing.md` | 16 | Screen gutters, card padding |
| `ManoSpacing.lg` | 24 | Between sections |
| `ManoSpacing.xl` | 32 | Hero breathing room |

## Corners

The brand draws exactly **two** corners:

| Token | Value | On |
|---|---|---|
| `ManoRadius.card` | 14 | Anything that holds content: cards, fields, sheets, notices |
| `ManoRadius.pill` | fully round | Anything you press: buttons, chips, filter pills |

`ManoRadius.sm`, `md` and `lg` exist only for older widgets. Don't use them in
new work.

## Layout

- **Phone first.** Design at 360 dp wide (the Samsung A36 we test on). Nothing may
  overflow at that width or at 2× text size.
- **Gutters.** 16 on the sides; 24 between sections.
- **Primary action at the bottom.** A screen's flame button sits at the bottom,
  within thumb reach, full width.
- **Platforms.** Android and iOS run the same screens. Avoid
  platform-specific UI.
