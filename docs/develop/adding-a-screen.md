# Adding a screen

A screen module touches four layers, in this order. Work test-first at each step.

## 1. Domain: is the data there?

If the port lacks an operation, add it to the port in `mano_domain`, then to the
mock adapter and (if live) the gateway adapter in `mano_data`. Business rules,
such as "only a pending request can be cancelled", go on the entity.

## 2. State: mano_session

Create `packages/mano_session/lib/src/<module>/` with your providers or
notifiers, then add one export line in `mano_session.dart`:

- **Reads:** a `FutureProvider` over the port provider.
- **Actions:** a `Notifier` whose methods return the port's `Result` and, on
  success, invalidate the providers that changed.

If the other app needs the same state, it already lives here: reuse it.

## 3. Screen: apps/<app>/lib/features/<module>/

- Watch providers, map domain values to widget arguments (labels, tones,
  `ManoFormat`), and build from `mano_ui` components.
- Handle loading, empty and error.
- At most one flame button.
- Register the route in the app's router, or reuse the one already registered
  for the module.

## 4. Tests and docs

| What | Where |
|---|---|
| State | `packages/mano_session/test/<module>/` |
| Screen | `apps/<app>/test/features/<module>/`, using `pumpRouterAt(tester, '/route', overrides: [...], session: ...)` |
| Device flow | `apps/<app>/integration_test/<module>_flow_test.dart` |
| Module doc | `docs/modules/<ID>-<module>.md`, plus a line in `docs/modules/index.md` and the nav in `zensical.toml` |

## Swapping a mock for a real backend

Write `Gateway<Port>` in `mano_data` (tested with `http`'s `MockClient`), then
change the default in `mano_session/lib/src/marketplace_providers.dart`. Nothing
above changes.
