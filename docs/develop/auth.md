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

One screen for both apps: `ManoPhoneSignInScreen` (`mano_ui`), after Wise's
"Log in". It is dumb; each app has a thin wrapper that maps
`phoneSignInProvider` onto it and routes the session.

| App | Entries | Wrapper |
|---|---|---|
| Requester | welcome "Iniciar sesión" and "Registrarse" | `SignInScreen` |
| Provider | welcome "Iniciar sesión" and "Crear cuenta" | `SignInStep` (onboarding step `signIn`) |

Sign-in and sign-up are one flow (SuperTokens `signinup`), so both welcome
pills open the same phone screen. They are both filled flame, side by side
(`ManoWelcomeActions`), with `ManoPlatformSignInButton` full width below; see
the exception in [Colour](../brand/colour.md).

The phone screen (`ManoSignInLayout`):

- round close top-left, title "Inicia sesión o regístrate";
- "País o región": a select with flag, name and dial code (Colombia +57 by
  default) that opens `ManoCountryPickerSheet`, searchable by name or code;
- "Número de celular": an outlined box, "Te enviaremos un código por SMS.";
- the flame "Continuar", then the underlined "¿Problemas para entrar?", which
  opens the email sheet titled as help ("¿No te llega el código?"); neither
  app has a support screen a signed-out person can use;
- pinned at the bottom, "O continúa con" and a `ManoBrandPillRow`: Google
  (Android) or Apple (iOS), and an email pill. The pills hide while the
  keyboard is up.

The code screen is the same layout with `ManoOtpField` and `ManoResendTimer`
(30 s), and no footer.

State lives in `phoneSignInProvider` (`mano_session`, auto-disposed): the
country, the number, the challenge, the code, busy and the failure. It hands
back the `Session`; the app routes it:

- requester: `OnboardingFlowNotifier.enter(session)` — a new account goes to
  the registration flow at the name step with `hasAccount`, which skips email
  and password (name → address → notifications);
- provider: `ProviderOnboardingNotifier.enter(session, phone:)` — a new
  account continues at the identity check with the verified phone filled in;
  a returning one leaves the onboarding for the shell.

Either way the notifier then calls `SessionManager.adopt(session)`.

The email pill and "¿Problemas para entrar?" open the credentials sheet,
which offers "Crear cuenta con correo" (the email sign-up flows). Google or
Apple on the welcome signs straight in; a failure opens the phone screen with
the notice.

## Auth screen hierarchy

Checked against Mobbin (iOS, November 2026) before the Google launch.

| Screen | What it shows |
|---|---|
| [Wise welcome](https://mobbin.com/screens/84b41552-3303-4521-a758-1eaa96419548) | "Log in" and "Register" as two equal filled pills, the platform button full width below, same height and gap |
| [Wise log in](https://mobbin.com/screens/c4d7f38e-4e0d-4367-a3de-6d8a5d80b326) | fields, one primary, an underlined trouble link; "Or log in with" pinned at the bottom over equal-width, mark-only outlined pills |
| [Airbnb log in or sign up](https://mobbin.com/screens/ab3008ee-f81f-4ede-a4ec-f279fc52b107) | one phone-or-email field, the primary, an "or" rule, then mark-only tiles |
| [Thumbtack sign up](https://mobbin.com/screens/3a91161d-1fc0-437e-a8dd-14d6122f2d5a) | three stacked social buttons, mark at a fixed leading inset, email demoted to a text link |
| [Monarch sign in](https://mobbin.com/screens/7a7fa802-5ee6-4eff-95e6-50d508b02444) | Apple and Google outlined, mark and label centred together, "OR" rule, then the primary |
| [Reddit](https://mobbin.com/screens/b36239f1-beb4-46c0-9ed2-77b90d038337), [AllTrails](https://mobbin.com/screens/e2b5110e-cc70-40a9-82e1-103526769639), [Digg](https://mobbin.com/screens/3f1952b1-1c07-4fe1-9ad5-d45a5900016e) | stacks of social buttons with the mark pinned at the leading edge so the marks form a column |
| [Recime](https://mobbin.com/screens/ebbb3230-aa98-4263-a6de-07ba6fd208c2), [Yazio](https://mobbin.com/screens/18a79b23-649c-4968-b3fa-713adcdb2602), [Craft](https://mobbin.com/screens/8d844293-c9d8-43e7-8755-7611dc149eff) | mark and label centred as one group; every outlined button has a clearly visible grey stroke |

Nu's sign-in did not come up on Mobbin (four queries, screens and flows).

The rules we follow:

- **One primary group.** The main way in is filled; social ways in are
  outlined white, never filled with our colour. The welcome's two flame pills
  are one group, not two primaries ([Colour](../brand/colour.md)).
- **One height.** Primary, platform and pill buttons are all 52 high and full
  pills, as on Wise and Monarch.
- **One gap.** Inside a group, `ManoSpacing.sm` (8) both between the two pills
  and above the platform button, matching Wise's grid.
- **Mark alignment.** A single full-width social button centres mark and label
  together (Monarch, Recime, Yazio). Pinning the mark at a leading inset only
  pays off in a stack of two or more (Thumbtack, Reddit), which we don't have.
- **Divider text.** Words, not a rule: "O continúa con" above the pills, as
  Wise's "Or log in with". Hidden while the keyboard is up.
- **Ordering.** The platform's own provider first (Google on Android, Apple on
  iOS), then email.
- **Visible stroke.** Google's white button carries a grey stroke. The white
  `ManoBrandButton` and the pill row both draw `colorScheme.outline`, at least
  3:1 against the surface on both themes (WCAG 1.4.11).

What changed: `ManoBrandButton`'s stroke moved from `outlineVariant` (stone,
about 1.2:1 on white, so the white Google pill nearly vanished on the white
welcome) to `outline`, the same stroke as `ManoBrandPillRow`. Everything else
already matched and stays as it is.

## Phone and code

1. `phoneE164('300 123 4567', Country.colombia)` turns what was typed into
   `+573001234567`. The code screen shows `maskedPhone`, e.g.
   `+57 300 *** 4567` or `+593 *** 4567`. Colombia wants ten digits starting with 3; the other
   `supportedCountries` (MX, PE, EC, CL, AR, VE, US, ES) take 6–12 digits.
   Null means the number does not fit, and the field shows
   `phoneNumberProblemCopy(country)`.
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
| mano-auth has no such provider (400, "could not be found") | `AuthUnavailable` |
| mano-auth rejects the id token (500) | `AuthUnavailable` |

Configuration:

- Google needs mano-auth's **web** OAuth client ID twice: `GOOGLE_CLIENT_ID`
  in mano-auth and `--dart-define=GOOGLE_SERVER_CLIENT_ID=…` in the app
  (`ManoConfig.googleServerClientId`). Android also needs an Android OAuth
  client for each package name and signing SHA-1 in the same Google Cloud
  project.
- Apple needs the "Sign in with Apple" capability on each bundle ID, and
  `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`,
  `APPLE_REQUESTER_CLIENT_ID`, `APPLE_PROVIDER_CLIENT_ID` in mano-auth.

### Google Cloud project

Google sign-in lives in the GCP project **`mano-app-prod`** (organisation
manoapp.co), in Google Auth Platform. The audience is External and still in
**testing**, so only the listed test users can sign in until the app is
published. With only `openid`, `email` and `profile` scopes, publishing needs no
Google verification.

| Client | Type | Client ID | Used by |
|---|---|---|---|
| mano-auth (web, server client) | Web | `937642558480-v2op3hleq83utq7kn077a8rdkif9ke6k` | mano-auth `GOOGLE_CLIENT_ID`; the apps' `GOOGLE_SERVER_CLIENT_ID` |
| Mano requester (Android, debug) | Android | `937642558480-av82…` | `com.manoinc.mano.requester`, debug SHA-1 |
| Mano provider (Android, debug) | Android | `937642558480-hgfn…` | `com.manoinc.mano.provider`, debug SHA-1 |
| Mano requester (iOS) | iOS | `937642558480-136cj6p11gv90pi2ickad9umij47s6fd` | `GIDClientID` in `apps/requester/ios/Runner/Info.plist` |
| Mano provider (iOS) | iOS | `937642558480-4m75tt29su4vg766mdo2vhmrqc4olqv2` | `GIDClientID` in `apps/provider/ios/Runner/Info.plist` |

All IDs end in `.apps.googleusercontent.com`. Client IDs are public. The web
client's **secret** is not: it goes to mano-auth as `GOOGLE_CLIENT_SECRET` and
is never committed.

The Android clients only have to exist. `google_sign_in` 7 goes through
Credential Manager with the web client as `serverClientId`, and Google matches
the package and SHA-1 itself, so there is no `google-services.json`. Each iOS
plist has `GIDClientID` and the reversed client ID as a URL scheme.

The registered SHA-1 is the shared debug key's,
`32:36:AB:DD:F3:B4:57:D7:14:BE:D1:89:0D:99:B5:66:55:F2:4D:C6`. Before release:

1. Add an Android client per package with the **upload key** SHA-1.
2. Add another with the **Play App Signing** SHA-1, taken from Play Console
   (Protect with Play, then App signing).
3. Put the Apple Team ID on both iOS clients.

Run with the shared, secret-free defaults:

    flutter run --dart-define-from-file=../../config/dev.json   # from apps/<app>

`config/dev.json` points at the local gateway (8082) and mano-auth (3001), and
carries the web client ID. Remember `adb reverse` for 8082 and 3001.

### mano-auth with Google, locally

From `../mano-auth`, with a throwaway in-memory core. The secret is read from
`~/.config/mano/google-web-client.json` (mode 600) at launch and never typed,
echoed or committed:

    docker run -d --rm --name st-core -p 3568:3567 \
      registry.supertokens.io/supertokens/supertokens-postgresql:12.2.0
    SUPERTOKENS_CORE_URL=http://localhost:3568 \
    GOOGLE_CLIENT_ID=937642558480-v2op3hleq83utq7kn077a8rdkif9ke6k.apps.googleusercontent.com \
    GOOGLE_CLIENT_SECRET="$(jq -r .web.client_secret ~/.config/mano/google-web-client.json)" \
    npm start

Check the provider is loaded without a phone: post a fake token.

    curl -s -X POST localhost:3001/auth/signinup \
      -H 'content-type: application/json' -H 'rid: thirdparty' -H 'st-auth-mode: header' \
      -d '{"thirdPartyId":"google","oAuthTokens":{"id_token":"<header.payload.sig>"},"role":"requester"}'

| Sent | Answer | Meaning |
|---|---|---|
| `thirdPartyId: google`, garbage token | 500 `JWSInvalid` from `verifyIdTokenFromJWKSEndpointAndGetPayload` | Google is configured and verifying |
| `thirdPartyId: google`, RS256 JWT with an unknown `kid` | 500 `JWSNoMatchingKey: no applicable key found in the JSON Web Key Set` | it fetched Google's JWKS |
| `thirdPartyId: facebook` | 400 `the provider facebook could not be found in the configuration` | the control: a provider that isn't there |

Verified on 2026-11-15. A bad token is a 500 with Express's HTML stack trace
outside production; the apps only read the status, so it lands as
`AuthUnavailable`.

## After a first sign-up

A phone account has no name or email yet, so the flow asks for a name (see
above). The requester's name reaches the profile and the greeting through
the registration flow, as an email sign-up's does. `ClientProfile` still
requires an email to save, so a phone requester cannot save the profile
editor until that rule changes. See [Profiles](profiles.md).

The access token of a phone account carries no `email`; the gateway's
verifier (`libmano-backapp`) already treats it as optional.
