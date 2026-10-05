# Provider journey (Mano Profesionales)

```mermaid
flowchart LR
    A[Sign up] --> B[Profile + documents]
    B --> C[Pending verification]
    C -- approved --> D[Publish offers]
    D --> E[Set availability]
    E --> F[Incoming requests]
    F -- accept --> G[Agenda]
    G --> H[Start] --> I[Finish<br/>log hours if hourly]
```

## Screens

| Tab | Screens | What happens |
|---|---|---|
| **Solicitudes** | Requests (Pendientes / Respondidas) | Read a request and its message; accept it (it lands on the agenda) or reject it with an optional reason. |
| **Agenda** | Agenda (Próximos / En curso / Historial) → Job | Start a job, finish it (hourly jobs log hours in half-hour steps), or cancel. |
| **+** | New offer | Publish an offer for a catalogue service. |
| **Bandeja** | Inbox → Chat | Talk to clients. |
| **Servicios** | My services → Offer editor; Availability | Edit, pause, reactivate or delete offers. Set weekly hours, block dates, share a calendar link. |

## Verification

New professionals start **pending verification**. They can complete their
profile, but cannot publish services or receive requests until Mano's staff
approve their documents. Staff can approve, reject (with a reason) or ask for
more information.

!!! note "Today"
    The verification gate isn't enforced yet: there is no auth backend. See
    `POLISH.md`.
