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
Screens 0–8"), in Mano's flame and Poppins, including Nu's in-app camera.

| Nu screen | Step (`IdentityFlowStep`) | Mano screen |
|---|---|---|
| — | `loading` | `ManoLoader` while `status()` answers |
| 0, tips | `intro` | "Vamos a tomar fotos de tu cédula para **confirmar tu identidad**", tips, Continuar |
| 1, man photographing his ID | `cedulaFront` | `ManoIllustratedStep`: `cedula.jpg`, "Toma la **foto del frente** de tu cédula", Tomar foto (back lens) |
| 2, camera with the card frame | camera | `IdentityCameraScreen`: `ManoCaptureFrame` (card) over the live back lens, "Muestra el frente de tu cédula", shutter, Ayuda, Cerrar; then the photo with Usar foto / Repetir |
| 3, Errores comunes | Ayuda | sheet listing the common mistakes |
| 4, back tips | `backIntro` | "Ahora necesitamos una **foto del reverso** de tu cédula", the same tips, Continuar |
| 5, close-up of the back | `cedulaBack` | `cedula.jpg` cropped toward the table, "**Voltea tu cédula** para tomar una foto de la parte de atrás", Tomar foto (back lens) |
| 6, camera, back | camera | the same, "Muestra el reverso de tu cédula" |
| 7, man taking a selfie | `selfie` | `selfie.jpg`, "¿Tomamos tu selfie?", Tomar foto (front lens) |
| 8, face circle | camera | `ManoCaptureFrame` (face oval) over the live front lens, "Mira a la cámara", no Ayuda |
| — | `review` | `ManoCaptureReviewRow` per photo with Repetir, then Enviar |
| — | `pending` | "Estamos revisando tus documentos" |
| — | `approved` | "Tu identidad está verificada" with the badge |
| — | `rejected` | The `reason`, and Intentar de nuevo (every photo again) |

The pictures are provider-app assets (`apps/provider/assets/identity/`,
1080 px tall JPEGs), handed to `ManoIllustratedStep` as its `illustration`
slot by `identityArt` (`features/identity/identity_art.dart`); `mano_ui`
ships none. A retake from the review skips the back tips.

`IdentityFlowNotifier` (`mano_session/verification/identity_flow.dart`)
holds the step and the photos (kept on the device for the thumbnails). Each
photo step names its lens (`IdentityFlowStep.facing`: back for the cédula,
front for the selfie); the app takes the photo and hands it to `usePhoto`,
which calls `submit`. A retake from the review returns to the review. There
is no liveness check: the vendor does liveness. `identityVerifiedProvider` is
true once approved.

### The camera

The system camera cannot be told which lens to open on many Android phones
(Samsung Camera ignores every front-camera hint), so identity photos use an
in-app camera (`apps/provider/lib/features/identity/camera/`):

| File | Does |
|---|---|
| `capture_camera.dart` | `CaptureCamera`: open a lens, preview, take, close, open settings; `CameraDenied` |
| `plugin_capture_camera.dart` | over the `camera` package; `pickLens` takes the asked lens or whichever exists |
| `capture_camera_provider.dart` | a fresh camera per capture; tests override it with a fake |
| `identity_camera_screen.dart` | ink ground, `ManoCaptureFrame` with the preview in its slot, shutter, then Usar foto / Repetir |

A refused camera shows "Necesitamos acceso a tu cámara…" with **Abrir
ajustes** (`app_settings`); coming back to the app tries the lens again. The
camera is let go when the app goes to the background. Android declares
`CAMERA`; iOS explains it in `NSCameraUsageDescription`. Chat and profile
photos still go through `MediaPicker` (image_picker).

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
  photos. A phone sign-up is not asked its number again. If the check was put
  off, the closing screen says "Falta verificar tu identidad" with
  **Verificar mi identidad** (opens `/profile/identity`) instead of "Tu cuenta
  está en revisión".
- Perfil: an "Verifica tu identidad" row (or "Verificación en revisión",
  "Identidad verificada") opens `/profile/identity`. The header's verified
  badge shows when the profile says so or the check is approved.
