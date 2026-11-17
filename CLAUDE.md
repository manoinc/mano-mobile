# CLAUDE.MD 

## Project overview 
mano-mobile is the shared frontend repo for the mobile UI/UX & frontend of all Mano applications, a home services marketplace app that connects customers with local professionals in their area (similar to TaskRabbit, Thumbtack or Urban Company but for Colombia).

## Repo map

Pub workspace — one `pub get`, one `pubspec.lock` at the root.

    apps/requester         Mano, for Solicitantes    com.manoInc.mano (iOS: com.manoinc.mano.requester)
    apps/provider          Mano Profesionales, for Proveedores com.manoinc.mano.provider
    packages/mano_domain   entities, ports, failures — zero dependencies
    packages/mano_data     adapters: GraphQL gateway (catalog live), in-memory mocks, secure storage
    packages/mano_ui       theme + dumb widgets — Flutter only
    packages/mano_session  composition root; the only member using Riverpod
    widgetbook             component catalogue (Widgetbook), published in the docs

Arrows point one way: `apps → mano_session → mano_data → mano_domain`, plus
`apps → mano_ui`. Enforced by the build, not by review —
`depend_on_referenced_packages` is an **error** in `mano_domain` and `mano_ui`,
so a cross-boundary import fails `dart analyze`:

- `mano_domain` imports nothing. Not Flutter, not Riverpod.
- `mano_ui` must not import `mano_domain`. A widget takes strings, booleans and
  callbacks; the screen does the mapping.
- Only `mano_session` may touch Riverpod.

See README.md for the rationale.

## Commands

```bash
dart analyze                                     # whole workspace, from root
cd packages/mano_domain  && dart test            # 241 — no Flutter binding
cd packages/mano_data    && flutter test         # 412
cd packages/mano_session && flutter test         # 418
cd packages/mano_ui      && flutter test         # 436
cd apps/requester        && flutter test         # 283
cd apps/provider         && flutter test         # 289
cd widgetbook            && flutter test         # 197 — every use case renders, every widget covered
tools/docs.sh serve                              # the handbook at localhost:8000
cd apps/<app> && flutter test integration_test -d RFGL20WAR9E  # on the A36, one at a time
cd apps/<app> && flutter test integration_test -d "iPhone 17"  # iOS simulator
dart tools/generate_logo_paths.dart              # after changing tools/brand/*.svg
cd apps/requester && flutter run -d RFGL20WAR9E --dart-define-from-file=../../config/dev.json  # the A36
```

## Docs

The Mano Handbook (`docs/`, Zensical through Docker via `tools/docs.sh`) and the
Widgetbook catalogue (`widgetbook/`). A new `mano_ui` widget needs a Widgetbook use case,
and the catalogue test fails without one. Recipes: `docs/develop/adding-a-screen.md`,
`docs/develop/adding-a-component.md`. The open polish backlog is in `POLISH.md`.
What the gateway really serves versus what is mocked: `docs/develop/backend-contract.md`.

## Coding style 

The shared rules (TDD, KISS/YAGNI, hexagonal, modular, config files, one-line
comments, no co-authoring) live in `../CLAUDE.md`. Specific to this repo:

Use TDD to make sure the code works E2E. 
The code must be structured in such a clean way that it looks the same in all apps and we don't have to duplicate effort across them. Both `android/` and `ios/` exist; keep everything platform-agnostic. iOS setup: `docs/develop/ios.md`.

Avoid extensive verbose comments or documentation inside the code, all comments must be one-liners, concise and easy to understand. Extensive documentation must sit outside the code, in the handbook's markdown files (`docs/`).
DO NOT coauthor any commits.

## Skills 

Use the Dart and Flutter plugin (@dart-flutter).
Before building any UI, make sure to use Mobbin MCP for looking up inspiration and see how others have done it (including competitors). Our UI/UX references are: Nubank, Wise, Cashapp, Airbnb. Our proxies (apps in similar markets) are: Taskrabbit, Thumbtack, Angi, Urban Company & GetNinjas (Brazil). 

## Testing 

Testing will always be done by default using an external phone plugged in. In my case I already have a Samsung A36 plugged in at all times when working with Flutter. Otherwise use Android's studio simulated environments. Android's CLI is already installed along with its skill. You can use it like `android --version`.
The A36 shows up as `RFGL20WAR9E`; pass it as `-d RFGL20WAR9E`.

Both apps default to the local gateway through `adb reverse`. It does not
survive unplugging or an adb restart:

```bash
adb reverse tcp:8082 tcp:8082   # mano-gateway
adb reverse tcp:3900 tcp:3900   # Garage (mano-media), for photo uploads
```

Chat photos and reviews need the full local stack (Garage, RabbitMQ,
mano-reviews): `../mano-gateway/docs/local-stack.md`.

## Design

The UI in the app must be minimalist, easy to use and simple. Our biggest references are apps like Wise, Nubank, Uber and Airbnb. Including their animations. 

### Branding

Defined once in `packages/mano_ui/lib/src/theme/mano_theme.dart`. Take colours
from `ManoColors`; never hard-code a hex in a screen.

    flame  #ff4a1c   the one hot surface — one primary action per screen
    clay   #c1602e   links, secondary emphasis
    ink    #201e1d   text, rules, dark ground
    muted  #4a4644   secondary text
    faint  #8a8481   tertiary text, placeholders, disabled
    sand   #f7f5f3   raised surfaces
    stone  #ede9e6   dividers, quiet borders

`ManoSpacing` (4pt scale), `ManoRadius` and `ManoMotion` are tokens too — use
them, not free numbers. The brand draws exactly two corners, `ManoRadius.card`
(14) and `ManoRadius.pill`, and one entrance curve, `ManoMotion.entrance`.

Type is Poppins, bundled in `mano_ui`; reach it through the text theme rather
than naming the family. The logo is generated Dart — `ManoWordmark`,
`ManoMonogram`, `ManoArchMotif` — never an image asset.

`mano_ui` ships no images at all. Illustrations and third-party marks are
app assets: see `apps/requester/assets/`. A shared widget that needs one takes
it as a `Widget` slot, the way `ManoBrandButton` takes `leading`.
