# REQ-07 Perfil (requester)

The Solicitante's own account: who they are, where work happens, how they will
pay, what they hired before, and how to reach Mano. Covers HU-C7 (perfil),
HU-C15 (direcciones y métodos de pago) and HU-C5 (PQRS).

Everything here is **mock-backed** except the avatar upload, which is live on
the gateway (see [Media](../develop/media.md)). The gateway's
`updateClientProfile` and `createSupportTicket` are stubs, profiles carry no
names, and billing is not on the gateway. See
[Backend contract](../develop/backend-contract.md).

## Screens and routes

| Route | Class | File |
|---|---|---|
| `/profile` | `ProfileTabScreen` | `screens/profile_tab_screen.dart` |
| `/profile/personal` | `PersonalInfoScreen` (+ `AvatarPicker`) | `features/profile/personal_info_screen.dart`, `avatar_picker.dart` |
| `/profile/addresses`, `/home/addresses` | `AddressesScreen` (+ `AddressFormSheet`) | `features/profile/addresses_screen.dart`, `address_form_sheet.dart` |
| `/profile/payments` | `PaymentMethodsScreen` (+ `PaymentMethodFormSheet`) | `features/profile/payment_methods_screen.dart`, `payment_method_form_sheet.dart` |
| `/profile/history` | `OrderHistoryScreen` | `features/profile/order_history_screen.dart` |
| `/profile/history/job/:id` | `JobDetailScreen` (REQ-04's) | `features/activity/job_detail_screen.dart` |
| `/profile/support` | `SupportScreen` | `features/profile/support_screen.dart`, `support_faq.dart` |
| `/profile/settings` | `SettingsScreen` | `features/profile/settings_screen.dart` |

Shared helpers: `profile_sheets.dart` (`confirmRemove`, `chooseAction`,
`showProfileMessage`) and `profile_copy.dart` (`FieldProblem` → Spanish).

## Perfil tab

The header shows the profile's name and photo once saved (else the account's
name). Each row pushes its route. A guest is asked for an account
(`requireAccount`) before Información personal, Métodos de pago and Historial;
Direcciones, Atención al cliente and Configuración stay open. Cerrar sesión (or
Iniciar sesión for a guest) stays last.

## Información personal

`clientProfileProvider` seeds the form: the name typed at sign-up
(`requesterGreetingName`) and the account's email (`clientProfileSeed`).
Guardar shows `ClientProfile.problems` inline (name 2–60 letters, a Colombian
mobile of ten digits starting with 3, an email), else saves and goes back with
"Guardamos tus datos.".

The avatar (`ManoAvatarEditor`) opens `ManoMediaSourceSheet`, then
`photoAttachmentsProvider(const AvatarUpload())` picks and uploads through the
live gateway. The picked bytes show at once with a spinner; on success
`clientProfileActions.setPhoto(url)` keeps the returned URL. A failed upload
says "No pudimos subir tu foto. Intenta de nuevo." and keeps the old photo.

## Direcciones guardadas

`savedAddressesProvider`, default first, each a `ManoOptionRow` with a
"Predeterminada" tag. Tapping a row offers Editar, Usar como predeterminada and
Eliminar (confirmed with "Sí, eliminar"). "Agregar dirección" opens the form
sheet: Nombre, Dirección, Barrio, Ciudad (Bogotá by default) and Indicaciones.
The first address becomes the default; removing the default promotes the next
(`withOneDefaultAddress`).

The Inicio pill shows `defaultAddressProvider` as "Casa · Calle 45 # 12-30"
(or "Agrega tu dirección") and opens `/home/addresses`.

## Métodos de pago

A `ManoNotice` says payments are not live yet. "Agregar método de pago" asks
Tarjeta or Nequi, then a form: card number (Luhn-checked) and expiry (MM/AA,
not past), or a Nequi mobile. Only `NewPaymentMethod.storedAs` is kept: brand
(Visa, Mastercard, Amex, else Tarjeta), last four and the default flag. The
full number never leaves the form. When billing lands, cards will be
**tokenised by Wompi** in the form and only the token and display data sent.
PSE has a `PaymentKind` for display but no add flow: it is a per-payment bank
redirect, not a saved method.

## Historial de pedidos

`orderHistoryProvider`: finished and cancelled jobs from `myJobsProvider`,
newest first, as `ManoProjectCard`s keyed `history-job-<id>`. A card opens the
job inside Perfil. Empty: "Aquí verás los trabajos terminados y cancelados."
with "Explorar servicios".

## Atención al cliente

Four FAQ rows (`ExpansionTile`), then `ManoSupportForm` (mano_ui, shared with
the provider app): Asunto (3–80) and Cuéntanos qué pasó (10–2000), the
gateway's `SupportTicketInput { subject description }`. `SupportDesk.file`
returns a `SupportTicket` whose `ticketNumber` is the radicado; the mock
numbers them `PQR-<year>-<00001>`. The screen swaps to "Recibimos tu mensaje"
with the radicado and "Listo".

## Configuración

Three `ManoToggleRow`s (`notificationPreferencesProvider`, in memory only until
push lands), Idioma fixed to Español (disabled), "Términos y privacidad" (a
sheet saying they will be published before launch) and the version
(`requesterAppVersion` in `config.dart`).

## Ports

| Port | Adapter | State (`mano_session/lib/src/…`) |
|---|---|---|
| `ClientProfileRepository` | `MockClientProfileRepository` | `account/client_profile_providers.dart` |
| `AddressBook` | `MockAddressBook` | `account/address_book_providers.dart` |
| `PaymentMethods` | `MockPaymentMethods` | `account/payment_method_providers.dart` |
| `SupportDesk` | `MockSupportDesk` | `support/support_desk_providers.dart` |
| `JobRepository` | REQ-04's | `account/order_history_provider.dart` |
| `MediaUploader` (avatar) | `GatewayMediaUploader` (live) | `media/` |

## Tests

- Domain: `packages/mano_domain/test/account/`
- Mocks: `packages/mano_data/test/account/account_mocks_test.dart`
- State: `packages/mano_session/test/account/`
- Widgets: `mano_avatar_editor_test.dart`, `mano_support_form_test.dart`
- Screens: `apps/requester/test/features/profile/`, `test/screens/profile_tab_screen_test.dart`
- Device: `apps/requester/integration_test/profile_flow_test.dart`

## Backend gaps

- `updateClientProfile` is a stub (D2) and `clientProfile` has no query, so
  the profile lives in memory.
- No saved-address or payment-method operations; no billing bridge (Wompi
  tokenisation, charges).
- `createSupportTicket` / `mySupportTickets` are stubs (D11).
