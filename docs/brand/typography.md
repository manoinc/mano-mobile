# Typography

**Poppins**, in three weights: Regular 400, SemiBold 600 and ExtraBold 800.
It is bundled in `mano_ui` rather than fetched from a font CDN.

Reach type through the theme, never by naming the font:

```dart
Text('Agenda tu cita', style: Theme.of(context).textTheme.headlineMedium)
```

## Scale

| Role | Size | Weight | Use |
|---|---|---|---|
| `displayLarge`–`displaySmall` | 44 / 38 / 32 | ExtraBold | Brand moments only: the wordmark, a hero's opening line |
| `headlineLarge` | 30 | ExtraBold | Screen titles on hero screens |
| `headlineMedium` | 27 | SemiBold | Screen titles ("Agenda tu cita") |
| `headlineSmall` | 24 | SemiBold | Large prices, sheet titles |
| `titleLarge` | 20 | SemiBold | Section headings |
| `titleMedium` | 17 | SemiBold | Card titles, list headings |
| `titleSmall` | 15 | SemiBold | Small headings |
| `bodyLarge` | 16 | Regular | Long text, descriptions |
| `bodyMedium` | 15 | Regular | Default body text |
| `bodySmall` | 13 | Regular | Metadata: dates, zones |
| `labelLarge` | 15 | SemiBold | Buttons, pills |
| `labelMedium` / `labelSmall` | 13 / 12 | SemiBold | Chips, badges, captions |

## Rules

- **Headings are tracked in:** -3% on display and headline sizes, -2% on titles.
  Nothing is ever tracked out.
- **Sentence case everywhere,** including buttons and labels. No ALL CAPS.
- **Body line height is generous** (1.4–1.45), so text stays readable at large
  system text sizes.
