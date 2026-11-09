# Signing in

Both apps sign in through `mano-auth` (SuperTokens FDI, header mode, port 3001),
switched on with `--dart-define=SUPERTOKENS_API_DOMAIN`. Three ways in, three
ports in `mano_domain/session/`:

| Way in | Port | SuperTokens recipe | Status |
|---|---|---|---|
| Phone + code (primary) | `PasswordlessAuth` | Passwordless, `PHONE`, `USER_INPUT_CODE` | port and `InMemoryPasswordlessAuth`; mano-auth recipe in STREAM-01 |
| Google (Android) / Apple (iOS) | `SocialAuth` | ThirdParty, native id-token | port and `InMemorySocialAuth`; recipe in STREAM-01 |
| Email + password (fallback) | `SessionRepository` | EmailPassword | **live** |

Every way in returns the same `Session`, so the rest of the app does not care
which one was used. New accounts carry the `role` signup field
(`requester` / `provider`), which mano-auth puts in the `st-role` claim.

## Phone and code

1. `colombianE164('300 123 4567')` turns what was typed into `+573001234567`;
   null means it is not a Colombian mobile, and the screen says so.
2. `sendCode(phone, role:)` returns an `OtpChallenge` (`deviceId`,
   `preAuthSessionId`, `phone`). The code screen shows `maskedPhone`.
3. `verify(challenge, code)` returns the `Session`, or:

| Failure | Copy (`authFailureCopy`) | Tone |
|---|---|---|
| `InvalidCode(attemptsLeft)` | "Ese código no es correcto. Te quedan N intentos." | error |
| `CodeExpired` | "Ese código venció. Pide uno nuevo." | error |
| `TooManyAttempts` | "Demasiados intentos. Espera un momento." | warning |

`isWellFormedOtp` gates the "Continuar" button: six digits.

Locally, mano-auth logs the code instead of texting it. Choosing an SMS
provider is still open.

## Google and Apple

`ManoPlatformSignInButton` shows Apple on iOS and Google on Android. The
button stays a white pill with the official mark, because both brands' rules
(and App Store review) forbid recolouring it. The marks are app assets
(`assets/brand/google-g.png`, `Icons.apple`), passed in as widgets.

Closing the provider's sheet is `SignInCancelled`, which shows nothing.

## After a first sign-up

A phone or social account has no name yet, so the flow asks for one and saves
it with `updateClientProfile` / `updateWorkerProfile(displayName)`. See
[Profiles](profiles.md).
