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
  mano_data        adapters: keystore, GraphQL (no auth adapter yet)
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

## Authentication: an open decision, not yet a dependency

`mano_domain` declares one port for this, `SessionRepository` — sign in,
restore, refresh, sign out, each returning a `Result` rather than throwing.
Nothing about it names an OAuth flow, a vendor, or a token shape. Which
provider actually signs a user in is not decided yet, and the architecture is
built so that not deciding costs nothing: `mano_session`'s
`sessionRepositoryProvider` currently points at a small placeholder
(`_NoAuthProviderChosen`) that renders the sign-in screen cleanly and reports
"not configured yet" the moment something tries to use it. The apps run, the
UI is real, and adopting a provider later is one `Provider` override —
nothing above `mano_data` changes.

When one is chosen, its adapter lands in `packages/mano_data/lib/src/session/`,
implementing `SessionRepository`. Until then there is nothing here pretending
to be more finished than it is.

## Failure: two mechanisms, on purpose

| Situation | Mechanism |
| --- | --- |
| Invariant violated, illegal argument, unreachable branch | `throw` an `Error` — never caught |
| Infrastructure failed in a way nobody modelled | Let it propagate; surfaces as `AsyncError` |
| A modelled boundary failure | `Result<T, Failure>` returned from the port |

Which is which is a judgement about who made the mistake. A cancelled sign-in
and an unreachable auth service are part of the contract, so they are values
the compiler forces you to handle. A null where there cannot be one is a bug,
so it crashes.

The useful consequence is at the top: **`AsyncValue.error` means the app has a
bug**, never that the user typed something wrong. Expected failures live in
`SignedOut.lastFailure`, so they cannot accidentally be rendered as a crash
screen.

## The brand, and the logo

The wordmark and the monogram are **generated Dart**, not assets:

```bash
dart tools/generate_logo_paths.dart
```

It reads `tools/brand/*.svg` and writes
`packages/mano_ui/lib/src/brand/mano_logo_paths.g.dart`. Re-run it after
replacing either file — that is the whole migration when the artwork stops
being called "provisional".

Generating rather than shipping the SVGs buys three things. `mano_ui` keeps its
"Flutter and nothing else" pubspec. The artwork's considerable dead padding is
normalised away, so `ManoWordmark` is exact at any size instead of floating
inside whatever box it is given. And the wordmark turns out to be drawn one
contour per letter, which is what lets the opening animation bring `m`, `a`,
`n` and `o` in one at a time without slicing anything up.

Poppins is bundled in `mano_ui` as `.ttf`, so any screen renders the brand
typeface without a network fetch.

## The opening animation

Android draws the monogram, `FlutterNativeSplash.preserve` holds that frame
until Flutter has painted, and `ManoOpening` continues from it: the letters
arrive, then the lockup travels to the corner as the screen fades up beneath
it. By the end the travelling wordmark sits exactly where the hero draws its
own, so the swap is invisible.

Two numbers make that work, and they are shared rather than repeated —
`ManoLockup.preferredOpeningHeight` is measured against what Android actually
renders, and `ManoLockup.restingHeight` and `.inset` are what
`ManoHeroScaffold` lays the wordmark out with. Change one without the other and
the logo jumps at the handover. Regenerate the native side with:

```bash
cd apps/requester && dart run flutter_native_splash:create
```

It plays once per cold start. A warm resume, a sign-out and a rebuild all find
it already done.

## Testing

| Layer | Runner | Needs |
| --- | --- | --- |
| `mano_domain` | `dart test` | nothing — no Flutter binding |
| `mano_session` | `flutter test` | nothing — `ProviderContainer.test()` with an overridden repository |
| `mano_ui` | `flutter test` | nothing — widgets take strings and callbacks |

```bash
cd packages/mano_domain  && dart test        # 21
cd packages/mano_session && flutter test     #  9
cd packages/mano_ui      && flutter test     # 48
```

`mano_data` has no tests right now: with the auth adapter gone, all that is
left is `GatewayClient` and `TokenStore`, neither of which was under test
before this either. Worth covering the next time either changes.

No test in the suite opens a browser, touches a keystore, or makes a request.

## Running against the local stack

Both apps default to a development gateway reached through `adb reverse`, so
the phone's `localhost` is the host's:

```bash
adb reverse tcp:8082 tcp:8082   # mano-gateway
```

The forward does not survive unplugging or an adb restart; re-run it.

```bash
cd apps/requester && flutter run
```

Sign-in has no backend yet — the screen renders and reports "not configured"
the moment it is pressed. Whatever provider comes next gets its own setup
instructions in this section.

## Pointing at a real environment

```bash
flutter run --dart-define=MANO_GATEWAY=https://api.mano.co/graphql
```

## Deliberately absent

- **No auth adapter.** See "Authentication" above — `SessionRepository` has no
  implementation yet, on purpose.
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
