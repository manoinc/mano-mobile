# mano-mobile

The two Mano apps, and the packages they share.

- **`apps/requester`** — Mano, for Solicitantes: people who need work done in
  their home (`com.manoinc.mano.requester`).
- **`apps/provider`** — Mano Pro, for Proveedores: people who do the work
  (`com.manoinc.mano.provider`).

Two apps, two store listings, two userbases. One repository, so the design
system and the domain are written once.

## Architecture

The arrows point one way:

```mermaid
flowchart TD
    subgraph Apps
        requester[apps/requester]
        provider[apps/provider]
    end
    subgraph Packages
        session[mano_session<br/>composition root, only Riverpod]
        data[mano_data<br/>adapters: GatewayClient, TokenStore]
        ui[mano_ui<br/>theme + dumb widgets]
        domain[mano_domain<br/>entities, ports, zero deps]
    end
    requester --> session
    requester --> ui
    provider --> session
    provider --> ui
    session --> data
    session --> domain
    data --> domain
```

Business logic must not depend on the presentation framework. That is enforced
by the build, not by review:

- `mano_domain` declares **no dependencies at all** — not Flutter, not
  Riverpod.
- `mano_ui` declares Flutter and nothing else — never `mano_domain`. A widget
  takes strings, booleans and callbacks; the screen does the mapping.
- Both set `depend_on_referenced_packages: error` in their
  `analysis_options.yaml`, so a boundary-crossing import fails `dart analyze`.
- Apps reach `mano_data` and `mano_domain` only through `mano_session`'s
  re-exports — never directly. The dependency graph above is the real one, not
  a simplification.

Try it:

```dart
// in packages/mano_domain/lib/anything.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
// error • The imported package 'flutter_riverpod' isn't a dependency
```

Detailed docs live outside this file — see mkdocs (or equivalent) once it's
set up. This README is just the map.

## Testing

```bash
cd packages/mano_domain  && dart test        # 21 — no Flutter binding needed
cd packages/mano_session && flutter test     #  9 — fake repository, no device
cd packages/mano_ui      && flutter test     # 48 — widgets take strings & callbacks
```

No test opens a browser, touches a keystore, or makes a network request.

`mano_data` has no tests yet — `GatewayClient` and `TokenStore` were never
covered, auth adapter or not.

## Quick start

Both apps default to a development gateway reached through `adb reverse`, so
the phone's `localhost` is the host's. The forward does not survive unplugging
or an adb restart; re-run it.

```bash
adb reverse tcp:8082 tcp:8082   # mano-gateway
cd apps/requester && flutter run
```

Sign-in has no backend yet — the screen renders and reports "not configured"
the moment it is pressed. Whatever provider comes next gets its own setup
instructions in this section.

### Pointing at a real environment

```bash
flutter run --dart-define=MANO_GATEWAY=https://api.mano.co/graphql
```
