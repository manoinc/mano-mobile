# Billing: coins and payouts

The provider app buys Mano coins and registers its payout account on the
gateway's D6 fields, served by mano-billing over gRPC
(`mano-gateway/docs/billing.md`). Offline mode and tests keep the in-memory
mocks.

## What is live and what is not

| Feature | Gateway fields | Status | Mobile |
|---|---|---|---|
| Coin packs | `coinPacks` (cheapest first, `Money` in whole COP) | **live** | `GatewayWalletRepository.packs` |
| Balance | `myCoinWallet { balance }` | **live** | `walletProvider` |
| History | `myCoinMovements(page: {first: 50})`, newest first | **live**: purchases, lead spends and lead refunds | `walletHistoryProvider` |
| Buying a pack | `buyCoinPack(packId, method, payerEmail, termsAccepted)` | **live**, Nequi and PSE | `coinPurchaseProvider` |
| Checkout terms | `checkoutTerms { label url }` | **live** | `checkoutTermsProvider` |
| PSE banks | `pseBanks { code name }` | **live** | `pseBanksProvider` |
| Lead prices | `leadPrices { defaultCoins prices { category coins } }` | **live** | `leadPricesProvider` |
| Payout banks | `payoutBanks { code name }` | **live** | `payoutBanksProvider` |
| Payout account | `registerPayoutAccount(input)` | **live**, write only | `GatewayPayoutAccounts` |
| Card payments | `card { token, installments }` | live on the gateway, **not offered**: needs the payment provider's client tokenizer | none (YAGNI) |
| Buying a project lead | `purchaseProjectLead(quoteId)` | **live** | `LeadActions.purchaseLead` (see below) |
| Saved payment methods | `myPaymentMethods` and friends | **stub** (no vault in billing) | `MockPaymentMethods` |
| Earnings | `earningsSummary` | **stub** | `MockEarningsRepository` |
| `myPayouts`, `requestPayout` | | live on the gateway | not used yet |

## Buying coins

1. The Recargar sheet reads `coinPacks`, `checkoutTerms` and `pseBanks`.
2. The provider picks a pack and a method:
   - **Nequi**: the Nequi mobile (`wallet { phone }`).
   - **PSE**: a bank from `pseBanks`, natural or juridical person, the
     document type and number (`pse { institutionCode, personType,
     legalIdType, legalId }`).
3. `payerEmail` is the signed-in account's email. When the session has none,
   the sheet asks for it ("Correo para el recibo").
4. The terms show as links, and "Acepto los términos de pago" must be on.
   Pagar stays disabled until `CoinPurchaseDraft.isValid`.
5. `buyCoinPack` answers `{ payment, nextAction }`. `coinPurchaseFromJson` maps it to
   a `CoinPurchase`:

| `nextAction.type` | `payment.status` | `CoinPurchase` | The sheet shows |
|---|---|---|---|
| `AWAIT_APPROVAL` | `PENDING` | `AwaitingApproval` | "Aprueba el pago en Nequi" and "Esperando a Nequi…" |
| `REDIRECT` with a URL | `PENDING` | `BankRedirect(url)` | "Termina el pago en tu banco" and "Ir a mi banco", which opens the URL in the system browser |
| `REDIRECT` without a URL, `PENDING`, or `NONE` while pending | `PENDING` | `PurchasePending` | "Estamos preparando tu pago"; the controller asks again |
| `NONE` | `COMPLETED` | `PurchaseCompleted` | "¡Listo! +N coins" |
| any | `FAILED` | `Err(DataRejected(failureReason))` | "No pudimos hacer la recarga" with "Intentar de nuevo" |

Coins are credited only when the charge completes, which billing learns from
a webhook or its reconciler. The balance stays the same until then, and the
app never adds the coins itself.

## The purchase controller

`CoinPurchaseController` (`mano_session/lib/src/wallet/`) holds a
`CoinPurchaseFlow`: `PurchaseIdle`, `PurchaseSubmitting`, `PurchaseWaiting(step)`,
`PurchaseCredited(coins, balance)`, `PurchaseTimedOut(step)` or
`PurchaseFailed(failure)`.

- `buy(draft)` reads the balance, calls `buyPack`, and on a waiting step
  starts a timer.
- Each tick reads `myCoinWallet`. A higher balance than at the start means
  the coins landed: `PurchaseCredited`, and the Billetera refreshes.
- A `PurchasePending` step calls `buyCoinPack` again on each tick. Billing
  keeps one live coin purchase per provider and returns it, so the bank's URL
  shows up once it is ready.
- After `maxPolls` ticks it stops at `PurchaseTimedOut`: "Tu pago sigue en
  proceso", with "Revisar de nuevo" (`checkNow()`). The coins may still land
  later; Billetera shows "Tienes una recarga en proceso" while waiting or
  timed out.
- The sheet calls `checkNow()` when the app resumes (back from Nequi or the
  bank), so the result shows without waiting for the next tick.
- Closing the sheet does not stop the wait. Opening it again shows the same
  step.

### Config

`BillingConfig` (`mano_session/lib/src/wallet/billing_config.dart`), through
`billingConfigProvider`:

| Field | Default | Meaning |
|---|---|---|
| `pollInterval` | 3 s | how often the balance is read while waiting |
| `settleTimeout` | 2 min | when the sheet stops waiting and says the payment is still in process |

Tests override it with short values. A PSE URL can take billing
`RECONCILE_AFTER` plus `RECONCILE_INTERVAL` (10 to 15 minutes by default) to
appear, which is longer than the timeout; "Revisar de nuevo" picks it up.

## Coins and leads

Coins are spent only on project leads; accepting a service request is free.
The selected worker buys the lead from Mis cotizaciones
(`purchaseProjectLead`): the gateway checks the quote in mano-projects,
billing spends the coins, and mano-projects unlocks the contact. Not enough
coins comes back as `FailedPrecondition: ... enough coins`, which the app
turns into the recharge prompt. What a lead costs comes from `leadPrices`,
keyed by category and folded to the app's canonical ids. After a purchase the Billetera refreshes, and
the movement shows as "Contacto de proyecto" (`LEAD_SPEND`) or "Reembolso de
contacto" (`LEAD_REFUND`).

## Payout account

- `payoutBanks` feeds "¿En qué banco?". The app has no static bank list: the
  offline mock serves `mockBanks` (`mano_data/lib/src/mock/mock_banks.dart`).
- `registerPayoutAccount(input)` sends exactly one of `wallet { phone }` or
  `bank { bankCode, accountType, accountNumber }`, plus `holder { name,
  email, legalIdType, legalId }`. The holder email is prefilled from the
  session ("Correo del titular").
- The gateway has **no read** of the payout account and **no remove**.
  `GatewayPayoutAccounts.current()` returns the account registered in this
  session only, so Perfil shows none after a restart, and "Eliminar cuenta"
  answers "No pudimos completar esta acción." Registering again replaces the
  account on billing's side.

## Errors

Billing errors reach the app as `"{TonicCode}: message"`, which `guardGateway`
maps: `NotFound` to `DataNotFound`, `Unavailable` to `DataUnavailable`, and
everything else (for example `FailedPrecondition: the payer must accept the
checkout terms`) to `DataRejected`. Screens never show the backend's wording.

## Opening the bank page

`externalLinkOpenerProvider` (`mano_session/lib/src/links/`) wraps
`url_launcher`'s `launchUrl(uri, mode: LaunchMode.externalApplication)`.
The app never calls `canLaunchUrl`, so no Android `<queries>` or iOS
`LSApplicationQueriesSchemes` entries are needed. Tests replace the provider
with a recorder.

## Trying it locally

Run mano-billing in memory with its fake payment provider and point the
gateway at it (`mano-gateway/docs/local-stack.md`):

```bash
(cd ../mano-billing && PLATFORM_FEE_BPS=1500 BIND_ADDR=127.0.0.1:50057 \
  METRICS_ADDR=127.0.0.1:9097 ./target/debug/manobilling)
# gateway: the usual env plus BILLING_URL=http://127.0.0.1:50057
```

The fake provider never settles a charge by itself. To land the coins, post a
signed `charge` notification to `POST /webhooks/fake`. The signature is
billing's `fake.rs` `sign` (a `DefaultHasher` over `fake-secret` and the
body), so it has to be computed by a small Rust program.

## Tests

- `mano_domain/test/wallet/coin_purchase_draft_test.dart`,
  `test/payouts/payout_account_draft_test.dart`.
- `mano_data/test/wallet/gateway_wallet_repository_test.dart`,
  `test/payouts/gateway_payout_accounts_test.dart` (`MockClient`), and the mock tests.
- `mano_session/test/wallet/coin_purchase_controller_test.dart` (`fake_async`).
- `apps/provider/test/features/wallet/recharge_sheet_test.dart`: packs, terms
  blocking, Nequi → coins land, PSE redirect, timeout, refusal.
  `test/features/payouts/payout_screen_test.dart`: billing's banks and a refused
  removal.
- `apps/provider/integration_test/wallet_flow_test.dart` and
  `account_flow_test.dart` on the A36.
