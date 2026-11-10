# Identity verification

A professional proves who they are before taking jobs: both sides of the
cédula and a selfie. Which company checks them (Didit, Tusdatos.co, or a
person on staff) sits behind one port, so it can change without touching a
screen.

## The port

`IdentityVerificationPort` (`mano_domain/verification/`):

| Method | Does |
|---|---|
| `status()` | Where the check stands |
| `submit(IdentityDocumentKind, PickedImage)` | Sends one photo; replaces an earlier one of the same kind |
| `finish()` | Sends everything for review; `DataRejected` while documents are missing |

`IdentityDocumentKind`, in the order the flow asks: `cedulaFront`,
`cedulaBack`, `selfie`.

`IdentityCheckStatus`:

| State | Meaning | Screen |
|---|---|---|
| `IdentityCheckInProgress(submitted)` | Collecting; `missing` lists the rest | the intro |
| `IdentityCheckPending` | Sent, no answer yet | "Estamos revisando tus documentos" |
| `IdentityCheckApproved` | Checked | the verified badge |
| `IdentityCheckRejected(reason)` | Refused; `reason` is shown | retry from the first step |

This is separate from `VerificationStatus` in `provider_onboarding.dart`,
which tracks staff review of the whole profile.

## Adapters

| Adapter | Status |
|---|---|
| `MockIdentityVerification` | in-memory; what the apps use today |
| Gateway (D10 `submitVerificationRequest`, `addVerificationDocuments`, `myVerificationRequest`) | the gateway still stubs D10; there is no media kind for identity documents |
| Didit | candidate: hosted liveness and document OCR, per-check pricing |
| Tusdatos.co | candidate: Colombian background checks (antecedentes) against the cédula number |

A vendor adapter lives in `mano_data/verification/`, implements the port and
is chosen in `identityVerificationProvider`. Nothing else changes.

### Gateway adapter sketch (not built)

When D10 is live and the gateway accepts an identity-document media kind:
`submit` uploads the photo through `MediaUploader` with a new
`UploadTarget` for identity documents and attaches it with
`addVerificationDocuments`; `finish` calls `submitVerificationRequest`;
`status` maps `myVerificationRequest` onto `IdentityCheckStatus`. Until then
there is no `UploadTarget` for identity documents: the port takes the
`PickedImage` itself, so the flow does not need one.

## The flow

The screens follow Nu's identity check step for step (Mobbin, "Nu iOS
Screens 0–8"), in Mano's flame and Poppins. Nu's own camera screens (dark
frame, "Ayuda" pill, face circle) have no Mano screen: Tomar foto opens the
system camera directly.

| Nu screen | Step (`IdentityFlowStep`) | Mano screen |
|---|---|---|
| — | `loading` | `ManoLoader` while `status()` answers |
| 0, tips | `intro` | "Vamos a tomar fotos de tu cédula para **confirmar tu identidad**", tips, Continuar |
| 1, man photographing his ID | `cedulaFront` | `ManoIllustratedStep`: `cedula.jpg`, "Toma la **foto del frente** de tu cédula", Tomar foto (rear camera), Ayuda |
| 3, Errores comunes | Ayuda | sheet listing the common mistakes |
| 4, back tips | `backIntro` | "Ahora necesitamos una **foto del reverso** de tu cédula", the same tips, Continuar |
| 5, close-up of the back | `cedulaBack` | `cedula.jpg` cropped toward the table, "**Voltea tu cédula** para tomar una foto de la parte de atrás", Tomar foto (rear camera), Ayuda |
| 7, man taking a selfie | `selfie` | `selfie.jpg`, "¿Tomamos tu selfie?", Tomar foto (front camera) |
| 2, 6, 8, camera | — | the system camera |
| — | `review` | `ManoCaptureReviewRow` per photo with Repetir, then Enviar |
| — | `pending` | "Estamos revisando tus documentos" |
| — | `approved` | "Tu identidad está verificada" with the badge |
| — | `rejected` | The `reason`, and Intentar de nuevo (every photo again) |

The pictures are provider-app assets (`apps/provider/assets/identity/`,
1080 px tall JPEGs), handed to `ManoIllustratedStep` as its `illustration`
slot by `identityArt` (`features/identity/identity_art.dart`); `mano_ui`
ships none. A retake from the review skips the back tips.

`IdentityFlowNotifier` (`mano_session/verification/identity_flow.dart`)
holds the step and the photos (kept on the device for the thumbnails). Tomar
foto opens the camera through `MediaPicker` (`PhotoSource.camera`) and calls
`submit`; a retake from the review returns to the review. There is no live
camera preview and no liveness check: the frame is a visual guide, and the
vendor does liveness. `identityVerifiedProvider` is true once approved.

The cédula photos open the rear camera and the selfie the front one
(`MediaPicker.pick(..., facing: CameraFacing.front)`, which
`ImagePickerMediaPicker` passes on as image_picker's `preferredCameraDevice`).

## The gate

The check can be put off ("Ahora no"), but until it is **approved** a pro can
only browse. A pending check does not count. Every action that commits a pro
to a client goes through one guard, `requireVerified` (`apps/provider/lib/features/identity/verification_gate.dart`):

- accepting or rejecting a request (Inicio)
- sending a quote (Cotizar gratis)
- buying a lead (Comprar contacto, from the project or from Mis cotizaciones)
- publishing, saving or reactivating an offer
- chatting with a client: sending a message or a photo, and opening a job's
  chat (Escribir). Reading the inbox and existing threads stays open. A
  message held by the gate stays in the composer: `ManoMessageComposer`
  clears only when `onSend` answers true.

A guest is asked to sign in first (`requireAccount`). A signed-in pro who is
not verified gets "Verifica tu identidad para continuar" with **Verificar
ahora** (opens `/profile/identity`) and **Ahora no**. The decision itself is
`IdentityFlowNotifier.verified()` in `mano_session`, which loads the status
first if nothing has asked yet.

The mock never approves on its own. To walk the gates, build the provider app
with `--dart-define=MANO_APPROVE_IDENTITY=true`
(`ManoConfig.approveIdentityChecks`): the mock then answers Enviar with
approval.

### Where it shows

- Provider onboarding: right after the account is created (`identity` step,
  between password and name). "Ahora no" puts it off; system back walks the
  photos.
- Perfil: an "Verifica tu identidad" row (or "Verificación en revisión",
  "Identidad verificada") opens `/profile/identity`. The header's verified
  badge shows when the profile says so or the check is approved.
