# Statuses

Every request, job and offer moves through a small set of states. The rules live
on the entities in `mano_domain`; screens only ask them (`job.canStart` and so
on).

## Request

```mermaid
stateDiagram-v2
    [*] --> pending: requester sends
    pending --> accepted: professional accepts (creates a job)
    pending --> rejected: professional rejects (optional reason)
    pending --> cancelled: requester cancels
```

## Job

```mermaid
stateDiagram-v2
    [*] --> scheduled: slot booked / request accepted
    scheduled --> inProgress: professional starts
    inProgress --> finished: professional finishes (hours if hourly)
    scheduled --> cancelled
    inProgress --> cancelled
    finished --> [*]: requester can rebook
    cancelled --> [*]: requester can rebook
```

| Rule | Where |
|---|---|
| Only a scheduled job can start | `Job.canStart` |
| Only a job in progress can finish | `Job.canFinish` |
| Scheduled or in-progress jobs can be cancelled | `Job.canCancel` |
| Finished or cancelled jobs can be rebooked | `Job.canRebook` |
| Hourly jobs need hours worked to finish | `Job.requiresHoursOnFinish` |

## Offer

```mermaid
stateDiagram-v2
    [*] --> active: published
    active --> paused
    paused --> active: reactivated
    active --> deleted
    paused --> deleted
```

Deleted offers are kept (soft delete) but disappear from every list.

## How statuses look

| Status | Label | Tone |
|---|---|---|
| Request pending / job scheduled | Pendiente / Programado | `info` |
| Job in progress | En curso | `warning` |
| Job finished / request accepted / offer active | Finalizado / Aceptada / Activa | `success` |
| Cancelled, rejected or paused | Cancelado / Rechazada / Pausada | `neutral` |
