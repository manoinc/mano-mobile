# iOS

Both apps build for iOS from the same Dart code as Android. Each app has its own
`ios/` Xcode project; plugins resolve through Swift Package Manager, so there is
no `Podfile` and CocoaPods is not needed.

## Requirements

- macOS with Xcode and an iOS Simulator runtime (`xcrun simctl list runtimes`).
- Flutter on `PATH`; `flutter doctor` should tick **Xcode**.

## Run

```bash
open -a Simulator
cd apps/requester && flutter run -d "iPhone 17" --dart-define-from-file=../../config/dev.json
```

The simulator shares the Mac's network, so `localhost:8082` reaches the gateway
directly — no `adb reverse`.

## Build without running

```bash
cd apps/<app> && flutter build ios --simulator --debug --dart-define-from-file=../../config/dev.json   # simulator
cd apps/<app> && flutter build ios --release --no-codesign --dart-define-from-file=../../config/prod.json  # device, unsigned
```

## Device flows

```bash
cd apps/<app> && flutter test integration_test -d "iPhone 17"
```

The simulator produces fewer incidental frames than a phone with a real
keyboard, so a test that taps right after `enterText` can hit a button that has
not rebuilt yet. Pump once after typing; see `_type` in
`apps/provider/integration_test/onboarding_flow_test.dart`.

## A physical iPhone

- **Signing.** Open `apps/<app>/ios/Runner.xcworkspace`, pick a Team under
  *Signing & Capabilities*. The simulator needs none.
- **Gateway.** The phone's `localhost` is the phone. Point it at the Mac in
  `.env` with `MANO_GATEWAY=http://<mac-lan-ip>:8082/graphql`, then:

  ```bash
  flutter run -d <iphone> --dart-define-from-file=../../config/dev.json --dart-define-from-file=.env
  ```

  `Info.plist` already allows local-network HTTP (`NSAllowsLocalNetworking`) and
  explains the local-network prompt (`NSLocalNetworkUsageDescription`).

## What lives in `ios/`

| | requester | provider |
|---|---|---|
| Bundle id | `com.manoInc.mano` | `com.manoInc.manoprofesional` |
| Home-screen name | Mano | Mano Profesional |
| Capabilities (`Runner.entitlements`) | Sign in with Apple | Sign in with Apple, Associated Domains (`applinks:manoapp.co`) |

The App ID in Apple Developer (team `G7R62XL9ST`) must enable the same capabilities.
| Language | `es` | `es` |

The icon and the launch screen are generated, not drawn by hand. After changing
`assets/icon/` or `assets/brand/splash.png`:

```bash
cd apps/<app> && dart run flutter_launcher_icons && dart run flutter_native_splash:create
```

The iOS icon is flattened onto the app's ground (`remove_alpha_ios`), because the
App Store rejects an icon with transparency.

## Not yet

- Permission strings for camera and photos, needed when onboarding gets a real
  document picker.
- Release signing and App Store Connect.
