# Signing in

Both apps sign in through `mano-auth` (SuperTokens FDI, header mode, port 3001),
switched on with `--dart-define=SUPERTOKENS_API_DOMAIN`. Three ways in, three
ports in `mano_domain/session/`:

| Way in | Port | SuperTokens recipe | Adapter (`mano_data/session/`) |
|---|---|---|---|
| Phone + code (primary) | `PasswordlessAuth` | Passwordless, `PHONE`, `USER_INPUT_CODE` | `SupertokensPasswordlessAuth` |
| Google (Android) / Apple (iOS) | `SocialAuth` | ThirdParty, native id token | `SupertokensSocialAuth` |
| Email + password (fallback) | `SessionRepository` | EmailPassword | `SuperTokensSessionRepository` |

The three adapters share one `SuperTokensFdi` (`superTokensFdiProvider`): it
posts in header mode, turns the token headers into a `Session` and keeps the
refresh token. So a session started by phone or Google renews and signs out
through `SessionRepository` like any other.

Every way in returns the same `Session`. `Session.isNewAccount` is true when
mano-auth answered `createdNewRecipeUser`. New accounts carry the `role`
(`requester` / `provider`, from `ManoConfig.appRole`), which mano-auth puts in
the `st-role` claim; the role is only granted when the account is created.

mano-auth's side lives on its branch `feat/passwordless-thirdparty`; its
README has the contract and the env variables.

## The screens

| App | Entry | Screen |
|---|---|---|
| Requester | onboarding "Iniciar sesión" (flame outline) | `SignInScreen` |
| Provider | welcome "Ya tengo cuenta" | `SignInStep` (onboarding step `signIn`) |

Both compose the same `mano_ui` pieces, after Airbnb's "Log in or sign up"
sheet with Wise's pills: `ManoSignInLayout` with `ManoPhoneField`
("Colombia (+57)" fixed, "Te enviaremos un código por SMS."), the flame
"Continuar", "o", then "Continuar con correo" and `ManoPlatformSignInButton`.
The code screen is `ManoSignInLayout` with `ManoOtpField` and
`ManoResendTimer` (30 s).

State lives in `phoneSignInProvider` (`mano_session`, auto-disposed): the
number, the challenge, the code, busy and the failure. It hands back the
`Session`; the app routes it:

- requester: `OnboardingFlowNotifier.enter(session)` — a new account goes to
  the registration flow at the name step with `hasAccount`, which skips email
  and password (name → address → notifications);
- provider: `ProviderOnboardingNotifier.enter(session, phone:)` — a new
  account continues at the name step with the verified phone filled in; a
  returning one leaves the onboarding for the shell.

Either way the notifier then calls `SessionManager.adopt(session)`.

"Continuar con correo" opens the old credentials sheet, which now offers
"Crear cuenta con correo" (the email sign-up flows). The requester's
"Registrarse" and the provider's "Crear cuenta profesional" still start email
sign-up.

## Phone and code

1. `colombianE164('300 123 4567')` turns what was typed into `+573001234567`;
   null means it is not a Colombian mobile, and the field shows
   `phoneNumberProblemCopy`.
2. `sendCode(phone, role:)` posts `/auth/signinup/code` and returns an
   `OtpChallenge` (`deviceId`, `preAuthSessionId`, `phone`). The code screen
   shows `maskedPhone`.
3. `verify(challenge, code)` posts `/auth/signinup/code/consume` with the
   role, and returns the `Session`, or:

| mano-auth answer | Failure | Copy (`authFailureCopy`) |
|---|---|---|
| `INCORRECT_USER_INPUT_CODE_ERROR`, attempts left | `InvalidCode(attemptsLeft)` | "Ese código no es correcto. Te quedan N intentos." |
| `INCORRECT_…` on the last attempt | `TooManyAttempts` | "Demasiados intentos. Espera un momento." |
| `EXPIRED_USER_INPUT_CODE_ERROR`, `RESTART_FLOW_ERROR` | `CodeExpired` | "Ese código venció. Pide uno nuevo." |
| `GENERAL_ERROR` (bad number, bad role) | `SignInRejected` | "No pudimos aceptar esos datos. Revísalos." |
| non-200 or unreachable | `AuthUnavailable` | "No pudimos conectarnos. Intenta de nuevo." |

Six digits verify on their own; "Continuar" does the same. Resend posts
`/auth/signinup/code/resend`.

Locally, mano-auth prints the code instead of texting it:

    [mano-auth] código para +573001234567: 482913

Choosing an SMS provider is still open (`mano-auth/src/supertokens/console-sms.ts`).

## Google and Apple

`ManoPlatformSignInButton` shows Apple on iOS and Google on Android. The
button stays a white pill with the official mark, because both brands' rules
(and App Store review) forbid recolouring it. The marks are app assets
(`assets/brand/google-g.png`, `Icons.apple`), passed in as widgets.

`SupertokensSocialAuth` asks an `IdTokenSource` for an id token
(`GoogleIdTokenSource` over `google_sign_in`, `AppleIdTokenSource` over
`sign_in_with_apple`), then posts `/auth/signinup` with `thirdPartyId`,
`oAuthTokens.id_token` and `role`. Apple also sends `clientType` = the role,
because each app's bundle ID is its own Apple client in mano-auth.

| Case | Result |
|---|---|
| The person closes the sheet | `SignInCancelled`, nothing shown |
| No `GOOGLE_SERVER_CLIENT_ID` in this build | `AuthUnavailable` |
| Platform misconfigured (`IdTokenUnavailable`) | `AuthUnavailable` |
| mano-auth has no such provider (404) | `AuthUnavailable` |

Configuration:

- Google needs mano-auth's **web** OAuth client ID twice: `GOOGLE_CLIENT_ID`
  in mano-auth and `--dart-define=GOOGLE_SERVER_CLIENT_ID=…` in the app
  (`ManoConfig.googleServerClientId`). Android also needs an Android OAuth
  client for each package name and signing SHA-1 in the same Google Cloud
  project.
- Apple needs the "Sign in with Apple" capability on each bundle ID, and
  `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`,
  `APPLE_REQUESTER_CLIENT_ID`, `APPLE_PROVIDER_CLIENT_ID` in mano-auth.

## After a first sign-up

A phone account has no name or email yet, so the flow asks for a name (see
above). The requester's name reaches the profile and the greeting through
the registration flow, as an email sign-up's does. `ClientProfile` still
requires an email to save, so a phone requester cannot save the profile
editor until that rule changes. See [Profiles](profiles.md).

The access token of a phone account carries no `email`; the gateway's
verifier (`libmano-backapp`) already treats it as optional.
