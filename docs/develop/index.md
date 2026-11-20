# Getting started

## Requirements

- Flutter (stable) and the Android SDK, with a phone attached over USB (we test on
  a Samsung A36, `-d RFGL20WAR9E`) or an emulator. For iOS, Xcode and a
  simulator; see [iOS](ios.md). Play Store builds: [Android release](release-android.md).
- Docker, for the docs and the local backend database.
- Optional: the backend repos next to this one (`../mano-gateway`, …).

## First run

```bash
flutter pub get                      # once, from the repo root (Pub workspace)
dart analyze                         # whole workspace
cd apps/requester && flutter run -d RFGL20WAR9E --dart-define-from-file=../../config/dev.json
cd apps/provider  && flutter run -d RFGL20WAR9E --dart-define-from-file=../../config/dev.json
```

## The repo

```
apps/requester        Mano (Solicitantes)          com.manoInc.mano (iOS: com.manoinc.mano.requester)
apps/provider         Mano Profesionales           com.manoinc.mano.provider
packages/mano_domain  entities, ports, rules — no dependencies
packages/mano_data    adapters: gateway GraphQL + in-memory mocks
packages/mano_session composition root; the only Riverpod user
packages/mano_ui      theme + presentational widgets
widgetbook            the component catalogue
docs                  this handbook
```

## Talking to the backend

API URLs and client keys are compiled in with `--dart-define-from-file`. The
shared values are committed in `config/dev.json` (local stack) and
`config/prod.json` (release); for personal overrides copy `.env.example` to a
git-ignored `apps/<app>/.env` and pass it second: the later file wins key by key. Locally both
apps call the gateway at `http://localhost:8082/graphql`. The phone reaches
your machine through `adb reverse tcp:8082 tcp:8082`, which you must re-run after
reconnecting the phone. Only the catalogue (search, services, offers) is live
today; everything else runs on in-memory mocks. See
[Backend contract](backend-contract.md) for running the gateway locally and
seeding it.

```bash
flutter run --dart-define-from-file=../../config/dev.json   # shared local defaults
cp .env.example .env                       # personal overrides, once per app
flutter run --dart-define-from-file=../../config/dev.json --dart-define-from-file=.env
```

## Next

- [Architecture](architecture.md): how the layers fit
- [Adding a screen](adding-a-screen.md) and [Adding a component](adding-a-component.md)
- [Testing](testing.md)
