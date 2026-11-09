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

The screens follow Nu's identity check (intro with tips, a dark capture
screen with a framed guide and an "Ayuda" pill, a face guide for the selfie)
and Airbnb/Uber/Wise for the oval selfie guide and the review-before-send.

| Step (`IdentityFlowStep`) | Screen |
|---|---|
| `loading` | `ManoLoader` while `status()` answers |
| `intro` | "Vamos a tomar fotos de tu cédula para **confirmar tu identidad**", tips, Continuar |
| `cedulaFront`, `cedulaBack` | Ink ground, `ManoCaptureFrame` (card), Tomar foto |
| `selfie` | Same, with the face (oval) guide |
| `review` | `ManoCaptureReviewRow` per photo with Repetir, then Enviar |
| `pending` | "Estamos revisando tus documentos" |
| `approved` | "Tu identidad está verificada" with the badge |
| `rejected` | The `reason`, and Intentar de nuevo (every photo again) |

`IdentityFlowNotifier` (`mano_session/verification/identity_flow.dart`)
holds the step and the photos (kept on the device for the thumbnails). Tomar
foto opens the camera through `MediaPicker` (`PhotoSource.camera`) and calls
`submit`; a retake from the review returns to the review. There is no live
camera preview and no liveness check: the frame is a visual guide, and the
vendor does liveness. `identityVerifiedProvider` is true once approved.

### Where it shows

- Provider onboarding: right after the account is created (`identity` step,
  between password and name). "Ahora no" puts it off; system back walks the
  photos.
- Perfil: an "Verifica tu identidad" row (or "Verificación en revisión",
  "Identidad verificada") opens `/profile/identity`. The header's verified
  badge shows when the profile says so or the check is approved.
