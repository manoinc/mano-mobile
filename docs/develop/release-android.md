# Android release (Play Store)

Mano (requester) ships to Play as **`com.manoInc.mano`** and Mano Profesionales
(provider) as **`com.manoInc.manoprofesional`**, exactly as registered in Play
Console. Package names are case-sensitive: the `I` is uppercase.

## Upload key

Play App Signing holds the app signing key; we only hold the **upload key**.

| | Requester | Provider |
|---|---|---|
| Keystore | `~/.mano-keys/mano-requester-upload.jks` | `~/.mano-keys/mano-provider-upload.jks` |
| Alias | `upload` | `upload` |
| Credentials | `apps/requester/android/key.properties` | `apps/provider/android/key.properties` |

Both keystores are PKCS12, RSA 2048, 10 000 days. `key.properties` is gitignored;
keep a copy in `~/.mano-keys/`. Create the provider's with:

```bash
keytool -genkeypair -v -keystore ~/.mano-keys/mano-provider-upload.jks \
  -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

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
cd apps/requester   # or apps/provider
flutter build appbundle --release --dart-define-from-file=../../config/prod.json
# build/app/outputs/bundle/release/app-release.aab
```

Bump `version:` in the app's `pubspec.yaml` before each upload; Play
rejects a repeated version code (the number after `+`). A new version name also
goes in `requesterAppVersion` or `providerAppVersion` (`lib/config.dart`); `test/version_test.dart` fails until it does.

If the build ends with *"failed to strip debug symbols"*, the AAB is still
written: Flutter's post-build check needs the Android SDK `cmdline-tools`.
Install them from Android Studio → SDK Manager → SDK Tools.

## Verify

```bash
jarsigner -verify build/app/outputs/bundle/release/app-release.aab
```
