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

`GatewayJobPaymentRepository` (`mano_data/payments/`) mirrors
`GatewayWalletRepository`: documents in `billing_documents.dart`, mappers in
`billing_json.dart` (`payJobVariables`, `jobPaymentFromJson`; the method
input is shared with `buyCoinPack`), and every call through `guardGateway`.
`jobPaymentRepositoryProvider` picks it, or `MockJobPaymentRepository` when
`offlineMarketplaceProvider` is on. The mock completes a payment on the next
read, like a webhook landing.

## Amount

`Job.payableCop` is what the checkout shows: the gateway's `finalAmount`
(mapped to `Job.finalAmountCop`), else the fixed price, else rate ×
`actualHours`. The payer pays `amount`; the 5% fee is never a line on the
breakdown.

## Checkout flow

`jobCheckoutProvider` (`JobCheckoutController`, auto-disposed with the
screen) runs one payment:

| `JobCheckoutFlow` | Means |
|---|---|
| `CheckoutIdle` / `CheckoutSubmitting` | the form; Pagar is busy while sending |
| `CheckoutWaiting(payment)` | Nequi approval, the bank's page, or a PSE link still pending |
| `CheckoutPaid(payment)` | settled; `jobPaymentProvider(jobId)` is invalidated so the job shows "Pagado" |
| `CheckoutTimedOut(payment)` | not settled within `BillingConfig.settleTimeout`; "Revisar de nuevo" looks again |
| `CheckoutFailed(failure)` | a refusal, or a `FAILED` payment's reason; "Intentar de nuevo" resets, and billing starts a new payment |

While waiting it polls `jobPayment` with backoff:
`BillingConfig.backoff(attempt)` doubles from `pollInterval` (3 s) up to
four times it, until `settleTimeout` (2 min). A missed read keeps waiting.
`checkNow()` looks at once, on app resume (back from Nequi or the bank).

## Screens (requester)

- Job detail: a finished job whose `jobPayment` is null or unsettled shows
  "Pagar $X" as the primary action and Calificar as the outline. Once paid it
  shows a "Pagado" chip and the usual Calificar / Volver a contratar.
- Checkout (`/projects/job/:id/pay`, also under order history): Airbnb's
  "Confirmar y pagar". Job summary, `ManoPriceBreakdown`, `ManoMethodOption`
  for Nequi and PSE (Tarjeta disabled, "Próximamente"), receipt email
  (prefilled from the account), terms toggle with links, one flame
  "Pagar $X". After Pagar the body becomes the status (`ManoPaymentStatus`);
  PSE's "Ir a mi banco" opens `redirectUrl` through `externalLinkOpenerProvider`.
- Métodos de pago (Perfil) follows Airbnb's "Payment methods": large title and
  grey subtitle, a `ManoMethodRow` per method (`PaymentBrandMark`, "Mastercard
  8341", "Vence: 05/2033", Editar), a compact ink "Agregar método de pago" and a
  `ManoInfoCard` ("Paga siempre a través de Mano") whose "Términos de pago" and
  "Más información" are underlined links. Saved methods are still a backend
  stub: `MockPaymentMethods` seeded with `demoPaymentMethods`.
