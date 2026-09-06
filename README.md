# mano-mobile

The two Mano apps, and the packages they share.

- **`apps/requester`** — Mano, for Solicitantes: people who need work done in
  their home.
- **`apps/provider`** — Mano Pro, for Proveedores: people who do the work.

Two apps, two store listings, two userbases. One repository, so the design
system, the domain and the authentication flow are written once.

## Layout

```
apps/requester     screens and routing        com.manoinc.mano.requester
apps/provider      screens and routing        com.manoinc.mano.provider
packages/
  mano_domain      entities, ports, failures  pure Dart, zero dependencies
  mano_data        adapters: OIDC, keystore, GraphQL
  mano_ui          theme and dumb widgets     Flutter only
  mano_session     composition root and session state, the only Riverpod
```

The arrows point one way:

```
apps ──▶ mano_session ──▶ mano_data ──▶ mano_domain
  └────▶ mano_ui                            ▲
                     (mano_session ─────────┘)
```

## The rule, and why it is not just a convention

Business logic must not depend on the presentation framework. That is easy to
say and easy to erode, so here it is enforced by the build rather than by
review:

- `mano_domain` declares **no dependencies at all**. Not Flutter, not Riverpod,
  not a functional-programming package.
- `mano_ui` declares Flutter and nothing else — in particular, not
  `mano_domain`. A widget therefore *cannot* accept a `Session`; it takes
  strings, booleans and callbacks, and the screen does the mapping.
- Both promote `depend_on_referenced_packages` to an **error** in their
  `analysis_options.yaml`.

That last point matters. A pub workspace resolves every member against one
shared dependency set, so Riverpod is physically reachable from `mano_domain`
even though its pubspec never names it. At its default severity the analyzer
would only mention that in passing. Promoted to an error, an import across a
boundary fails `dart analyze` and fails CI.

Try it:

```dart
// in packages/mano_domain/lib/anything.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
// error • The imported package 'flutter_riverpod' isn't a dependency
```

## Failure: two mechanisms, on purpose

| Situation | Mechanism |
| --- | --- |
| Invariant violated, illegal argument, unreachable branch | `throw` an `Error` — never caught |
| Infrastructure failed in a way nobody modelled | Let it propagate; surfaces as `AsyncError` |
| A modelled boundary failure | `Result<T, Failure>` returned from the port |

Which is which is a judgement about who made the mistake. A mistyped password
and an unreachable Keycloak are part of the contract, so they are values the
compiler forces you to handle. A null where there cannot be one is a bug, so it
crashes.

The useful consequence is at the top: **`AsyncValue.error` means the app has a
bug**, never that the user typed something wrong. Expected failures live in
`SignedOut.lastFailure`, so they cannot accidentally be rendered as a crash
screen.

## Testing

| Layer | Runner | Needs |
| --- | --- | --- |
| `mano_domain` | `dart test` | nothing — no Flutter binding |
| `mano_data` | `flutter test` | nothing — every collaborator is faked |
| `mano_session` | `flutter test` | nothing — `ProviderContainer.test()` with an overridden repository |

```bash
cd packages/mano_domain  && dart test        # 21
cd packages/mano_data    && flutter test     # 13
cd packages/mano_session && flutter test     #  8
```

No test in the suite opens a browser, touches a keystore, or makes a request.

## Running against the local stack

Both apps default to a development stack reached through `adb reverse`, so the
phone's `localhost` is the host's. That keeps the token's `iss` claim matching
what `mano-gateway` was configured with — reaching Keycloak by any other host
mints tokens the gateway refuses.

1. Keycloak on `localhost:8080` with the `mano` realm
   (`libmano-backapp/scripts/setup-keycloak-realm.sh`).
2. `mano-gateway` on `localhost:8082`.
3. Forward both to the phone:

```bash
adb reverse tcp:8080 tcp:8080
adb reverse tcp:8082 tcp:8082
```

4. `cd apps/requester && flutter run`

The forwards do not survive unplugging or an adb restart; re-run them.

### Registering the app clients

Each app authenticates as its own public OIDC client — `mano-requester-app`
and `mano-provider-app`:

```bash
./scripts/setup-keycloak-clients.sh
```

Idempotent, and it needs the `mano` realm to exist first
(`libmano-backapp/scripts/setup-keycloak-realm.sh`). Each client gets PKCE
(S256) enforced, direct access grants **disabled** so the password grant is not
available, the redirect URI matching `ManoConfig.redirectUrl`, and an
**audience mapper for `mano-gateway`** — without which Keycloak issues tokens
carrying no `aud` and the gateway rejects every one.

## The Keycloak login theme

Sign-in happens in the system browser, not in the app -- that is what keeps
Mano from ever handling a password and what makes SSO, MFA and social login
possible later. The handoff is only jarring if the page it opens looks like
someone else's, so `keycloak-theme/mano` puts Mano's brand on it.

```bash
./scripts/deploy-keycloak-theme.sh
```

It copies the theme into the container, points the realm at it, and switches
the realm to Spanish. Idempotent; re-run it after recreating the container.

The theme inherits from `keycloak.v2`, so **every** page the authentication
flow can reach is branded -- password reset, one-time codes, required actions,
consent, errors -- not just the login form. A themed login followed by an
unthemed "update your password" page would be worse than no theme.

Details worth knowing:

- **Tokens are copied from `mano-landing`, not re-picked.** The login page is
  where someone decides whether to trust that this is really Mano, and a
  near-miss on the orange is worse than no branding.
- **Poppins is bundled**, not fetched from Google Fonts: a login page should
  not depend on a third party being reachable, or tell one who is signing in.
- **Spanish is the only locale.** Listing a second makes Keycloak render a
  language picker above the form, and a phone set to English would otherwise
  get untranslated Keycloak defaults.
- **The copy is Mano's, not a translation of Keycloak's.** Errors say what
  happened and what to do; they do not apologise. A wrong username and a wrong
  password give the same message, so an attacker cannot use it to learn which
  accounts exist.

## Pointing at a real environment

```bash
flutter run \
  --dart-define=MANO_ISSUER=https://accounts.mano.co/realms/mano \
  --dart-define=MANO_GATEWAY=https://api.mano.co/graphql \
  --dart-define=MANO_ALLOW_INSECURE=false
```

`MANO_ALLOW_INSECURE` exists solely because local Keycloak is plain HTTP over
loopback. It must be `false` anywhere a real user is involved.

## Deliberately absent

- **No GraphQL client library.** There is one query and no agreed schema;
  adopting a client and its cache now would commit to a shape nobody has
  settled. `HttpGatewayClient` is the only file that changes later.
- **No router.** One screen per session state, so a redirect table would be
  indirection with nothing to indirect. `go_router` earns its place when a
  signed-in user has somewhere to navigate to.
- **No use-case classes.** A `SignInUseCase` forwarding to
  `sessionRepository.signIn()` is a file pretending to be a layer. One appears
  when there is real orchestration across repositories.
- **No domain screens.** The catalogue lives behind `jobservicecrud`, which the
  gateway cannot yet reach. Screens built against a guessed schema get
  rewritten.
