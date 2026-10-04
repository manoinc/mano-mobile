# Architecture

Hexagonal (ports and adapters), split into a Pub workspace so the boundaries are
enforced by the build rather than by review.

```
apps/requester ─┐
apps/provider ──┼─> mano_session ─> mano_data ─> mano_domain
                └─> mano_ui
```

| Layer | Package | Holds | May import |
|---|---|---|---|
| Domain | `mano_domain` | entities, enums, pure rules, ports (abstract interfaces), `Result`, failures | nothing |
| Adapters | `mano_data` | gateway adapters (`GatewayTransport`, `Gateway*`) and in-memory `Mock*` adapters | `mano_domain`, `http`, Flutter plugins |
| Composition | `mano_session` | one Riverpod `Provider<Port>` per port, plus feature notifiers | `mano_data`, `mano_domain`, Riverpod |
| Design system | `mano_ui` | tokens, `ManoFormat`, dumb widgets (strings, bools, callbacks) | Flutter only |
| Apps | `apps/*` | routes, screens, domain → widget mapping | `mano_session`, `mano_ui` |

`depend_on_referenced_packages` is an error in `mano_domain` and `mano_ui`, so a
cross-boundary import fails `dart analyze`.

## Conventions

- **Entities** are hand-written `final class`es with `const` constructors, `==`,
  `hashCode`, `toString` and, where state changes, `copyWith`. No codegen.
- **Money** is whole pesos (`amountCop`), matching the gateway. Legacy
  `ServiceListing`/`Project` still carry cents.
- **Reads** return `Future<T>` and may throw; `FutureProvider`/`AsyncValue`
  turns that into an error state.
- **Mutations** return `Result<T, DataFailure>` (`DataNotFound`,
  `DataRejected`, `DataUnavailable`). A failure the user can cause is a value,
  never an exception.
- **Lifecycle rules** live on the entity (`Job.canStart`, `canFinish`,
  `canCancel`, `canRebook`, `requiresHoursOnFinish`;
  `ServiceRequest.canRespond`; `AvailabilityRule.isValid`). Screens ask the
  entity; mock adapters enforce the same rules.
- **Widgets** never see domain types. The screen maps a status to a label and a
  `ManoStatusTone`, a price to `ManoFormat.cop(...)`, a time to
  `ManoFormat.time(...)`.
- **Copy** is Spanish (Colombia).

## Swapping a mock for a real adapter

1. Write `Gateway<Port>` in `mano_data/lib/src/<feature>/`, tested with
   `package:http/testing.dart` `MockClient`.
2. Change the default in `mano_session/lib/src/marketplace_providers.dart`.

Nothing above `mano_session` changes.

## Adding a screen module

1. **Domain:** if the port is missing an operation, add it to the port, the mock
   and the gateway adapter, test-first.
2. **State:** put feature state in `mano_session/lib/src/<module>/` as a
   `Notifier`/`AsyncNotifier` over the port provider, and export it from
   `mano_session.dart`. If both apps need the same state, it lives here once.
3. **Screens:** they go in `apps/<app>/lib/features/<module>/`. Routes are
   already registered in `shell/app_router.dart` (requester) and
   `shell/provider_router.dart` (provider).
4. **Shared widgets:** reuse `mano_ui` first. A widget two modules need goes in
   `mano_ui` as a new file with its own test.
5. **Tests:**
   - Widget tests go in `apps/<app>/test/features/<module>/`, using
     `test/support/pump_app.dart` (`pumpRouterAt(tester, '/route',
     overrides: [...])`).
   - The flow test goes in `apps/<app>/integration_test/<module>_flow_test.dart`
     and runs on the device.
6. **Docs:** write `docs/modules/<ID>-<module>.md`.

## Testing

| Suite | Command | Runs on |
|---|---|---|
| Domain | `cd packages/mano_domain && dart test` | host, no Flutter |
| Data, session, UI | `flutter test` in each package | host |
| Apps (widget) | `flutter test` in each app | host |
| Apps (integration) | `flutter test integration_test -d RFGL20WAR9E` | the A36 |

`flutter test integration_test` always targets a device. Only one run can use
the phone at a time.
