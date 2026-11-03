# PROV-09 Billetera & Recargar (provider)

Providers pay for leads with Mano coins. Billetera shows the balance and its
history; Recargar buys a pack by Nequi or PSE. Live on billing (D6), see
[Billing](../develop/billing.md).

## Screens and routes

| Route | Class | File | Entry |
|---|---|---|---|
| `/wallet` | `WalletScreen` | `features/wallet/wallet_screen.dart` | Billetera tab |
| sheet | `showRechargeSheet` | `features/wallet/recharge_sheet.dart` | "Recargar" on Billetera, or the insufficient-coins sheet on Inicio |

## Billetera

`ManoBalanceHero` with the live balance, "Recargar" (the one flame action) and
"Cómo funciona". While a purchase is waiting or timed out, a `ManoNotice` says
"Tienes una recarga en proceso". Activity is grouped as Esta semana, Este mes
and Antes.

## Recargar

Researched on Mobbin. Airbnb's "Confirm and pay" and Thumbtack's payment
details give the single checkout: terms right above one pay button. Cash App
does its top-up in a sheet. Wise and Nu give the status screens: a plain
headline, what happens next, and a live waiting line.

1. **Form** (`PurchaseForm`): billing's packs (`ManoPackOption`, the middle
   one preselected), "Cómo quieres pagar" (Nequi / PSE chips), then:
   - Nequi: "Celular de Nequi".
   - PSE (`PseFields`): "Elige tu banco" opens `showBankPicker` over
     `pseBanks`, then Persona natural / jurídica, the document type and
     "Número de documento".
   - "Correo para el recibo", only when the session has no email.
   - `ManoToggleRow` "Acepto los términos de pago", with the terms as links.
   - "Pagar · $45.000", disabled until the draft is valid.
2. **Status** (`PurchaseStatusView` over `ManoPaymentStatus`):
   - "Aprueba el pago en Nequi" / "Esperando a Nequi…".
   - "Termina el pago en tu banco" with "Ir a mi banco" (system browser).
   - "Estamos preparando tu pago" while the PSE link is not ready.
   - "¡Listo! +28 coins" / "Ya tienes 53 Mano coins." with "Listo".
   - "Tu pago sigue en proceso" with "Revisar de nuevo".
   - "No pudimos hacer la recarga" / "El pago fue rechazado. No te cobramos
     nada." with "Intentar de nuevo", which goes back to the filled form.

Every status but the success also offers "Cerrar". Closing does not cancel the
wait.

## Domain and state

| Layer | What |
|---|---|
| `mano_domain/src/wallet/` | `CoinPurchaseDraft` (+ `CoinPurchaseProblem`), `CoinPurchase` (`AwaitingApproval`, `BankRedirect`, `PurchasePending`, `PurchaseCompleted`), `CheckoutTerm`, `WalletRepository` |
| `mano_domain/src/shared/` | `Bank`, `LegalIdType` + `isValidLegalId` (shared with payouts) |
| `mano_data` | `GatewayWalletRepository`, `billing/billing_documents.dart`, `billing/billing_json.dart`, `MockWalletRepository` |
| `mano_session/src/wallet/` | `walletRepositoryProvider`, `coinPacksProvider`, `checkoutTermsProvider`, `pseBanksProvider`, `CoinPurchaseController` / `coinPurchaseProvider`, `BillingConfig` |
| `mano_session/src/links/` | `externalLinkOpenerProvider` (url_launcher) |
| `mano_ui` | `ManoPaymentStatus` (new), `ManoPackOption`, `ManoToggleRow` |

## Tests

- `apps/provider/test/features/wallet/recharge_sheet_test.dart`,
  `wallet_screen_test.dart`, with `test/support/fake_billing.dart`
  (`ScriptedWallet`, `FakeLinks`, `billingOverrides`).
- `apps/provider/integration_test/wallet_flow_test.dart`: Nequi until the
  coins land (offline mock), PSE until the bank page opens.
