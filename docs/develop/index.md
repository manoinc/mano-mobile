# Getting started

## Requirements

- Flutter (stable) and the Android SDK, with a phone attached over USB (we test on
  a Samsung A36, `-d RFGL20WAR9E`) or an emulator.
- Docker, for the docs and the local backend database.
- Optional: the backend repos next to this one (`../mano-gateway`, …).

## First run

```bash
flutter pub get                      # once, from the repo root (Pub workspace)
dart analyze                         # whole workspace
cd apps/requester && flutter run -d RFGL20WAR9E
cd apps/provider  && flutter run -d RFGL20WAR9E
```

## The repo

```
apps/requester        Mano (Solicitantes)          com.manoinc.mano.requester
apps/provider         Mano Profesionales           com.manoinc.mano.provider
packages/mano_domain  entities, ports, rules — no dependencies
packages/mano_data    adapters: gateway GraphQL + in-memory mocks
packages/mano_session composition root; the only Riverpod user
packages/mano_ui      theme + presentational widgets
widgetbook            the component catalogue
docs                  this handbook
```

## Talking to the backend

Both apps call the gateway at `http://localhost:8082/graphql`. The phone reaches
your machine through `adb reverse tcp:8082 tcp:8082`, which you must re-run after
reconnecting the phone. Only the catalogue (search, services, offers) is live
today; everything else runs on in-memory mocks. See
[Backend contract](backend-contract.md) for running the gateway locally and
seeding it.

```bash
flutter run --dart-define=MANO_GATEWAY=https://api.mano.co/graphql   # another gateway
```

## Next

- [Architecture](architecture.md): how the layers fit
- [Adding a screen](adding-a-screen.md) and [Adding a component](adding-a-component.md)
- [Testing](testing.md)
