# Paying for a job

The requester pays once the job is **finished**. Booking stays free: billing's
`payJob` only accepts a finished job, and the provider's payout is the amount
less the 5% platform fee ([Billing](billing.md)).

## Gateway

| Field | Shape |
|---|---|
| `payJob(jobId, method, payerEmail, termsAccepted)` | `PaymentResult { payment nextAction }`; idempotent per job |
| `jobPayment(jobId)` | the same, or null when unpaid |
| `checkoutTerms`, `pseBanks` | shared with coin purchases |

`method` is exactly one of `wallet { phone }` (Nequi), `pse { institutionCode
personType legalIdType legalId }` or `card { token installments }`. Card waits
on a tokenizer, as it does for coins.

## Domain

`JobPaymentRepository` (`mano_domain/payments/`): `pay(JobPaymentDraft)`,
`payment(jobId)`, `checkoutTerms()`, `pseBanks()`.

`JobPaymentDraft.problems` gates "Pagar". The checks are the same as a coin
purchase: a Nequi mobile, or a PSE bank and a valid id, plus a payer email and
accepted terms.

`JobPayment.status` maps `nextAction`:

| `nextAction.type` / `payment.status` | `JobPaymentStatus` | App |
|---|---|---|
| `AWAIT_APPROVAL` | `awaitingApproval` | "Aprueba el pago en Nequi", poll `jobPayment` |
| `REDIRECT` | `redirect` | open `redirectUrl` in the browser, poll on return |
| `PENDING` | `pending` | poll |
| `COMPLETED` | `completed` | the job shows "Pagado" |
| `FAILED` | `failed` | show `failureReason`, offer to retry |

`amount` is what the payer is charged. `feeAmount` comes out of the provider's
payout, not on top of it.

## Adapters

`MockJobPaymentRepository` completes a payment on the next read, like a
webhook landing. `GatewayJobPaymentRepository` arrives with STREAM-03 and
mirrors `GatewayWalletRepository`.
