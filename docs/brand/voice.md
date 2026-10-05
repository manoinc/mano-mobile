# Voice and copy

Mano speaks like a helpful neighbour who happens to be very organised: warm,
direct and brief.

## Rules

- **Spanish (Colombia), in *tú*.** "Agenda tu cita", not "Agende su cita".
- **Say what happens next.** Prefer "Solicitud enviada · te avisaremos cuando
  responda" to "Éxito".
- **Buttons are verbs:** *Continuar, Agendar, Publicar, Aceptar*.
- **Errors explain and offer a way out.** "No pudimos cargar tus solicitudes" plus
  a *Reintentar* button. Never show technical detail.
- **No invented facts.** If the backend doesn't give a provider's name, show
  "Profesional", not a made-up one.

## Formats

Always format through `ManoFormat`, so every screen agrees:

| Value | Call | Output |
|---|---|---|
| Money (whole pesos) | `ManoFormat.cop(45000)` | `$45.000` |
| Time | `ManoFormat.time(t)` | `3:00 p. m.` |
| Day | `ManoFormat.dayMonth(t)` | `12 oct` |
| Day and time | `ManoFormat.dateTime(t)` | `12 oct, 3:00 p. m.` |
| Weekday | `ManoFormat.weekdayShort(t)` | `lun` |
| Relative | `ManoFormat.relative(t, now)` | `5m`, `3h`, `2d` |

**Hourly prices** read `$45.000 /hora`; **fixed prices** read `$120.000 precio fijo`.

## Words we use

| Use | Not |
|---|---|
| In the requester app the other side is the **profesional**; in the provider app, the **cliente** | Trabajador, usuario |
| Solicitud (request), Trabajo (job), Oferta (offer) | Pedido, Orden |
| Agenda (provider calendar), Actividad (requester history) | Calendario, Historial |
| Bandeja (inbox) | Mensajes |
