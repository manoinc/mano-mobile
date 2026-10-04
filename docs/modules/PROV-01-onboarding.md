# PROV-01 Professional Onboarding (Provider)

A signed-out professional creates an account: a profile (name, phone, coverage
zone), identity documents, then a submission for staff review. The account then
sits pending verification (flow T-1 in `flujos_usuario_mano.pdf`).

## Screens and routes

No route. `lib/main.dart`'s root shows `ProfessionalOnboardingScreen(onFinished:)`
when signed out; `onFinished` enters the shell locally because there is no auth
backend yet.

All files live in `apps/provider/lib/features/onboarding/`.

| File | What it draws |
|---|---|
| `professional_onboarding_screen.dart` | Switches between the steps with `ManoStepTransition` (keyed by step). A `PopScope` sends system back to `notifier.back()` on every step except the welcome. |
| `steps/welcome_step.dart` | `ManoHeroScaffold`: headline, footnote explaining Mano Profesionales, primary **Crear cuenta profesional** (`start()`), secondary **Ya tengo cuenta** (`sessionProvider.notifier.signIn()`). A `SignedOut.lastFailure` is shown as a `ManoNotice` and dismissed with `acknowledgeFailure()`. While the sign-in call runs, a local `_busy` flag makes the buttons spin. |
| `steps/profile_step.dart` | `ManoStepScaffold`: **Nombre para mostrar**, **Celular** (phone keyboard), **Zona de cobertura** (helper "Por ejemplo, Chapinero."). Errors appear inline after the first refused **Continuar**, then update as you type. |
| `steps/documents_step.dart` | Rows "Documento de identidad (frente)" and "(reverso)" (required), and "Certificados o soportes (opcional)". Each row has **Adjuntar**, which flips to "Adjuntado". **Continuar** stays disabled until both ID sides are attached. |
| `steps/review_step.dart` | A summary of name, normalised phone, zone and attached documents. Primary **Enviar a revisión** spins while submitting. A failure shows `ManoNotice(failure.message)` above the summary, and the data is kept. |
| `steps/pending_step.dart` | "Tu cuenta está en revisión", a `ManoStatusChip('En revisión', warning)`, and an explanation (you can complete your profile, but you can't publish services or receive requests until approved). Primary **Explorar la app** → `onFinished()`. |
| `onboarding_copy.dart` | Spanish copy for `ProfileProblem`s, document labels, and `AuthFailure` messages and tones (the same wording as the requester's sign-in). |

`apps/provider/lib/screens/sign_in_screen.dart` was unused and has been deleted.

## State flow

All of it is in `packages/mano_session/lib/src/provider_onboarding/`.

- `provider_profile_validation.dart`: pure functions.
  - `enum ProfileProblem { empty, tooShort, invalid }`.
  - `validateDisplayName(String)`: rejects blank and 1 character.
  - `validatePhone(String)`: Colombian mobile, `3` followed by 9 digits; spaces, dashes, brackets and `+57` are allowed.
  - `validateWorkZone(String)`: rejects blank.
  - `normalizePhone(String) → String?`: returns the 10 digits.
- `provider_onboarding_notifier.dart`:
  - `providerOnboardingProvider`: `NotifierProvider<ProviderOnboardingNotifier, ProviderOnboardingState>`. Not auto-dispose, so the draft survives the root rebuilding on a failed sign-in.
  - `ProviderOnboardingStep { welcome, profile, documents, review, pending }`.
  - `ProviderDocument { idFront, idBack, certificates }`, each with `slug` and `required`.
  - `ProviderOnboardingStatus` (sealed): `Idle`, `Submitting`, `Failed(DataFailure)`.
  - `ProviderOnboardingState`:
    - Fields: `step`, `displayName`, `phone`, `workZone`, `attached` (`Map<ProviderDocument, String>`), `showProblems`, `status`.
    - Getters: `profileComplete`, `documentsComplete`, and `draft`. `draft` builds the `WorkerProfileDraft`, trimmed with the phone normalised; its documents are in enum order.
  - Notifier methods:
    - `start()` goes to profile.
    - `editDisplayName`, `editPhone`, `editWorkZone`.
    - `attach(doc)` records `placeholder://<slug>`.
    - `next()` advances only if the step is complete; otherwise it sets `showProblems`.
    - `back()` goes review → documents → profile → welcome. Each step change clears `showProblems` and `status`.
    - `submit()` works only on review and ignores a second call while one is in flight. `Ok` → `pending`. `Err` → `Failed`, with step and data kept. It does nothing if the provider was disposed meanwhile.
    - `acknowledgeFailure()`.

Nothing is invalidated: no other provider reads verification state yet.

## Ports and adapters

| Port | Provider | Adapter today |
|---|---|---|
| `ProviderOnboardingRepository.submit` | `providerOnboardingRepositoryProvider` | `MockProviderOnboardingRepository` (in memory; rejects an empty name or no documents) |
| `SessionRepository.signIn` | `sessionRepositoryProvider` via `sessionProvider` | `_NoAuthProviderChosen` → `AuthUnavailable` ("No pudimos conectar…") |

## Shared widgets

None added. Uses `ManoHeroScaffold`, `ManoStepScaffold`, `ManoStepTransition`,
`ManoTextField`, `ManoTextAction`, `ManoNotice` and `ManoStatusChip`. The
document row and summary row are private to the feature.

## Tests

- `packages/mano_session/test/provider_onboarding/provider_onboarding_notifier_test.dart` (13):
  - validation rules;
  - the initial state;
  - `start`;
  - a refused profile shows problems, a valid one advances;
  - documents need both ID sides;
  - placeholder paths;
  - `back` keeps the draft;
  - submit success sends the exact `WorkerProfileDraft` and lands on pending;
  - submit failure keeps the data, and `acknowledgeFailure` clears it;
  - submit is a no-op off the review step.
- `apps/provider/test/features/onboarding/professional_onboarding_screen_test.dart` (7):
  - the welcome entries;
  - **Ya tengo cuenta** shows the sign-in failure notice;
  - inline profile errors, including a live phone error;
  - documents **Continuar** stays disabled until both ID sides are attached;
  - back keeps the data;
  - submit → pending → **Explorar la app** calls `onFinished`;
  - a failed submit shows the notice and keeps the review.
- `apps/provider/test/root_test.dart` (existing): signed out lands here; `onFinished` enters the shell.
- `apps/provider/integration_test/onboarding_flow_test.dart` (device):
  - start signed out;
  - **Crear cuenta profesional**, fill the profile, **Continuar**;
  - attach both ID sides, **Continuar**;
  - **Enviar a revisión** → pending;
  - **Explorar la app** → `ProviderNavShell`.

## Gaps and follow-ups

- **No file or image picker.** **Adjuntar** records `placeholder://id-front`, `placeholder://id-back` and `placeholder://certificates`. Going live needs a picker plugin (camera and gallery for ID photos, files for certificates), permissions on Android and later iOS, and real local paths in `WorkerProfileDraft.documentPaths`. Certificates are one row with one placeholder; multiple certificates would need a list.
- **No photo.** T-1 lists a profile photo; the domain draft has no field for it.
- **No registration backend.** "Crear cuenta profesional" creates nothing: there is no auth provider, so email, phone or Google sign-up (T-1 step 1) is not possible. **Ya tengo cuenta** always reports `AuthUnavailable`.
- **The verification port is mocked.** No gateway operation exists for a worker profile, document upload or `VerificationStatus`. Document upload would also need storage, such as pre-signed URLs.
- **The pending state does not persist.** After a cold start the professional is signed out and sees the welcome again. Once auth exists, the root should read `ProviderOnboardingRepository.status()` and gate publishing services and receiving requests on `approved`. Today the shell does not enforce that restriction.
- **Validation could move to the domain.** `validateDisplayName`, `validatePhone`, `validateWorkZone` and `normalizePhone` are pure functions in `mano_session` because this module could not edit `mano_domain`. They belong on or beside `WorkerProfileDraft`, like `registration_validation.dart`.
