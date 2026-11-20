# Android release (Play Store)

Mano (requester) ships to Play as **`com.manoInc.mano`**, exactly as registered in
Play Console. Package names are case-sensitive: the `I` is uppercase.

## Upload key

Play App Signing holds the app signing key; we only hold the **upload key**.

| | |
|---|---|
| Keystore | `~/.mano-keys/mano-requester-upload.jks` (PKCS12, RSA 2048, 10 000 days) |
| Alias | `upload` |
| Credentials | `apps/requester/android/key.properties` (gitignored), copy in `~/.mano-keys/` |

`key.properties` holds four lines. `storeFile` must be an absolute path: Gradle
does not expand `~`.

```properties
storeFile=/Users/<you>/.mano-keys/mano-requester-upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

Back up `~/.mano-keys/` to the team password manager. If the upload key is lost,
request an upload key reset in Play Console → Test and release → App integrity.

Without `key.properties` the release build falls back to the debug keys, so
`flutter run --release --dart-define-from-file=../../config/dev.json` keeps working on any machine;
Gradle warns, as Play rejects a debug-signed bundle. CI builds that way.

## Build

```bash
cd apps/requester
flutter build appbundle --release --dart-define-from-file=../../config/prod.json
# build/app/outputs/bundle/release/app-release.aab
```

Bump `version:` in `apps/requester/pubspec.yaml` before each upload; Play
rejects a repeated version code (the number after `+`). A new version name also
goes in `requesterAppVersion` (`lib/config.dart`); `test/version_test.dart` fails until it does.

If the build ends with *"failed to strip debug symbols"*, the AAB is still
written: Flutter's post-build check needs the Android SDK `cmdline-tools`.
Install them from Android Studio → SDK Manager → SDK Tools.

## Verify

```bash
jarsigner -verify build/app/outputs/bundle/release/app-release.aab
```
