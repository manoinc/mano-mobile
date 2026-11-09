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
| `IdentityCheckInProgress(submitted)` | Collecting; `missing` lists the rest | the next missing step |
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
