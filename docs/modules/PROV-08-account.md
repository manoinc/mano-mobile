# PROV-08 Account & Profile (provider)

The professional keeps their public profile up to date, files a PQRS and
registers where earnings are paid. All three start from Perfil and open on the
root navigator, over the bottom bar. Everything but the avatar upload is a
mock until the gateway serves it (see [Backend contract](../develop/backend-contract.md)).

## Screens and routes

| Route | Class | File | Entry |
|---|---|---|---|
| `/profile/edit` | `EditProfileScreen` | `features/profile/edit/edit_profile_screen.dart` | "Editar perfil" under the Perfil header |
| `/profile/support` | `SupportScreen` | `features/support/support_screen.dart` | "Ayuda y PQRS" row |
| `/profile/payout` | `PayoutScreen` | `features/payouts/payout_screen.dart` | "Cuenta para pagos" row |

Editing and payouts ask guests to sign in (`AccountReason.profile`,
`AccountReason.payouts`); support is open to guests.

### Edit profile (HU-T3)

One scrolling form with "Guardar cambios" pinned at the bottom, like Airbnb's
and LinkedIn's profile editors:

- **Photo**: `AvatarEditor`. "Cambiar foto" opens `ManoMediaSourceSheet`, then
  `photoAttachmentsProvider(AvatarUpload())`, which is **live** (mano-media).
  The local bytes show at once with a spinner; a failed upload offers a retry.
- **Nombre para mostrar** (1–60 characters) and **Sobre ti** (up to 280, with a
  counter).
- **Servicios que ofreces**: `ManoChoiceChip`s over `ServiceCategories.all`,
  at least one.
- **Zonas donde trabajas**: removable chips plus an "Agregar zona" field, at
  least one; a zone already listed (any case) is ignored.
- **Fotos de tus trabajos**: `ManoPhotoPickerGrid`, up to 9, saved photos first.
  New ones go through `PortfolioUpload`, which falls back to the mock uploader.

Guardar stays shut until something changed, the draft is valid and no upload
is running. Back with unsaved changes asks "¿Descartar los cambios?" (Seguir
editando / Descartar cambios). A save shows "Perfil actualizado" and Perfil
reloads.

### Ayuda y PQRS (HU-T4)

`ManoStepScaffold` around `ManoSupportForm` (shared with the requester app):
Petición · Queja · Reclamo · Sugerencia, Asunto (≤ 120), "Cuéntanos qué pasó"
(≤ 2000), and "Enviar". Filed, it shows `SupportFiledView`: "Recibimos tu
queja", the radicado (`MANO-yyyymmdd-0001` from the mock), a "Radicada" chip,
the date, and "Listo". A failure stays on the form as a `ManoNotice`.

### Cuenta para pagos (HU-T6)

Wise's "Add a recipient" for the first screen, then one question per screen
like the provider onboarding:

1. **¿Dónde quieres recibir tus pagos?** Nequi or Cuenta bancaria (rows, a tap
   moves on).
2. **¿En qué banco?** (bank only) from `ColombianBanks`.
3. **¿Cuál es tu Nequi?** a mobile, 10 digits starting with 3 (`+57` allowed);
   or **Tu cuenta**: Ahorros / Corriente and a 6–20 digit number (spaces,
   dots and dashes are dropped).
4. **¿A nombre de quién está?** holder name (prefilled from the profile),
   CC / CE / NIT / PP and the document (CC 6–10 digits, CE 6–12 alphanumeric,
   NIT 9–10 digits with the check digit, PP 5–12 alphanumeric). "Guardar
   cuenta" registers it.

With an account saved the route shows it masked ("Nequi" over "•••• 4567", or
"Davivienda" over "Corriente · •••• 5678", and "Andrés Castro · CC •••• 4050"),
with "Cambiar cuenta" (runs the questions again) and "Eliminar cuenta". Perfil's
row reads "Bancolombia · •••• 1234". No money moves (YAGNI).

## Domain and state

| Layer | What |
|---|---|
| `mano_domain/src/profile/` | `ProviderProfileDraft` (validation, `toggleSkill`, `addZone`), `ProviderProfileEditor` port; `ProviderProfile` gained `skills` and `portfolioUrls` |
| `mano_domain/src/support/` | `SupportTicketDraft {kind, subject, description}`, `SupportTicket {number, status, createdAt}`, `SupportDesk` port |
| `mano_domain/src/payouts/` | `PayoutDestination` (`NequiDestination` / `BankDestination`), `AccountHolder`, `PayoutAccount`, `PayoutAccountDraft` (problems carry their step), `PayoutAccounts` port, `ColombianBanks` |
| `mano_domain/src/shared/colombian_mobile.dart` | `normalizeColombianMobile`, also used by onboarding |
| `mano_data` | `MockProviderProfileRepository` (now also the editor), `MockSupportDesk`, `MockPayoutAccounts` |
| `mano_session` | `providerProfileActionsProvider`, `supportDeskProvider`, `payoutAccountProvider`, `payoutActionsProvider` |

The payout model follows mano-billing's `RegisterPayoutAccount`: destination
`WalletDestination{phone}` (Nequi) or `BankDestination{bank_code, account_type,
account_number}`, plus `AccountHolder{name, legal_id_type, legal_id}`. Billing's
holder also takes an `email`, which the app has no source for yet (SuperTokens
tokens carry none). Bank codes are ACH Colombia's; confirm them against
billing / Wompi before going live.

## Tests

- `packages/mano_domain/test/provider_profile_draft_test.dart`,
  `test/support/`, `test/payouts/`.
- `packages/mano_data/test/profile/`, `test/support/`, `test/payouts/`.
- `packages/mano_session/test/profile/profile_editing_test.dart`,
  `test/support/`, `test/payouts/`.
- `packages/mano_ui/test/widgets/mano_choice_chip_test.dart`,
  `mano_support_form_test.dart`.
- `apps/provider/test/features/profile/edit_profile_screen_test.dart`,
  `test/features/support/`, `test/features/payouts/` through the real router,
  with `fakeMediaOverrides()` (`test/support/fake_media.dart`: a 1×1 PNG picker
  and an instant uploader).
- `apps/provider/integration_test/account_flow_test.dart`: edit and save,
  file a queja, register Nequi.
