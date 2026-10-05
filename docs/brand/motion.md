# Motion

One curve and a handful of durations, taken from the landing site so timing feels
the same everywhere. In code they are `ManoMotion.*`.

## Curves

| Token | Curve | Use |
|---|---|---|
| `ManoMotion.entrance` | `cubic-bezier(0.23, 1, 0.32, 1)` | Anything **arriving**: fast start, long settle |
| `ManoMotion.exit` | ease-in cubic | Anything **leaving** |

## Durations

| Token | ms | Use |
|---|---|---|
| `quick` | 160 | A border taking focus, a chevron turning, a chip selecting |
| `normal` | 200 | A press, a fade, a notice appearing |
| `sheet` | 320 | A sheet climbing into place |
| `opening` | 1150 | The cold-start brand sequence |

## Rules

- **Motion explains where things come from.** Steps slide in the direction you
  are going (`ManoStepTransition`); sheets rise from the bottom.
- **Press feedback is a small scale-down** (`ManoPressScale`), not a ripple splash.
- **Respect reduced motion.** When the system asks for less motion, sheets
  appear without climbing.
