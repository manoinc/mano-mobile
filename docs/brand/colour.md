# Colour

Seven colours, taken from the landing site so the app and the marketing page are
the same orange. In code they are `ManoColors.<name>`; a hex never appears in a
screen.

| | Name | Hex | Use it for |
|---|---|---|---|
| <span class="swatch" style="background:#ff4a1c"></span> | **flame** | `#ff4a1c` | The one primary action per screen. Selected states. |
| <span class="swatch" style="background:#c1602e"></span> | **clay** | `#c1602e` | Links, quiet buttons, secondary emphasis. |
| <span class="swatch" style="background:#201e1d"></span> | **ink** | `#201e1d` | Text, rules, selected chips, the dark ground. |
| <span class="swatch" style="background:#4a4644"></span> | **muted** | `#4a4644` | Secondary text. |
| <span class="swatch" style="background:#8a8481"></span> | **faint** | `#8a8481` | Tertiary text, placeholders, disabled. |
| <span class="swatch" style="background:#f7f5f3"></span> | **sand** | `#f7f5f3` | Raised surfaces: fields, bubbles, cards. |
| <span class="swatch" style="background:#ede9e6"></span> | **stone** | `#ede9e6` | Dividers and quiet borders. |

## Status colours

Statuses use `ManoStatusTone`, never a raw colour:

| Tone | Reads as | Example |
|---|---|---|
| `info` | neutral fact, waiting | Pendiente, Programado |
| `warning` | in motion, needs attention | En curso |
| `success` | done, good | Finalizado, Activa |
| `neutral` | closed, inactive | Cancelado, Pausada |

`success` is the only green in the product. It has no brand token on purpose.

## Do and don't

<div class="grid-2" markdown>

!!! success "Do"
    - Use flame once per screen, for the action you most want taken.
    - Put secondary actions in clay text or an ink outline.
    - Use sand for anything raised off the page.

!!! failure "Don't"
    - Put two flame buttons on one screen, including one per card in a list.
    - Use flame for decoration, icons or headings.
    - Type a hex value in a screen.

</div>

!!! warning "Known issue"
    Some Material surfaces (cards, unselected pills, app bars) currently come out
    pinkish, because the theme derives them from the flame seed. They should be
    sand and stone. This is tracked in `POLISH.md`.
