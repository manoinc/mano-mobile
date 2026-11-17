# Testing

We work test-first: write the failing test, watch it fail, make it pass.

| Suite | Command | Runs |
|---|---|---|
| Domain | `cd packages/mano_domain && dart test` | host, no Flutter |
| Data, session, UI | `flutter test` in the package | host |
| Catalogue | `cd widgetbook && flutter test` | host: every use case renders, every widget is covered |
| Apps | `flutter test` in the app | host |
| Device flows | `cd apps/<app> && flutter test integration_test/<x>_test.dart -d RFGL20WAR9E` | the phone |
| Device flows, iOS | `cd apps/<app> && flutter test integration_test -d "iPhone 17"` | the simulator; see [iOS](ios.md) |

## Habits

- **Fakes over mocks.** Tests implement the port with a small fake, or use the
  in-memory `Mock*` adapter, and override the provider.
- **Screens are tested through the real router** with `pumpRouterAt`.
- **Phone size.** Set `tester.view.physicalSize = Size(1080, 2340)` and
  `devicePixelRatio = 3` when layout matters.
- **Locale-proof.** Tap `find.byType(BackButton)` rather than
  `tester.pageBack()`, which looks for an English tooltip.

!!! warning "Device runs uninstall the app"
    `flutter test integration_test` installs a test build and uninstalls it
    afterwards. Run one at a time, as the phone is shared. Reinstall when done:
    `flutter build apk --release --dart-define-from-file=.env && adb install -r build/app/outputs/flutter-apk/app-release.apk`.
