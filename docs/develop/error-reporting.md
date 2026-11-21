# Error reporting

Both apps report crashes to Sentry (one Flutter project, `mano-requester@<version>` and
`mano-provider@<version>` releases). `runWithErrorReporting` in `mano_session` wraps
`runApp`; the SDK installs `FlutterError.onError`, `PlatformDispatcher.onError` and
native crash handling on Android and iOS.

## When it reports

Only when `SENTRY_DSN` is set. `config/prod.json` sets it with `SENTRY_ENVIRONMENT=production`;
`config/dev.json` does not, so local runs and tests report nothing. To try it locally, put
both keys in your `apps/<app>/.env` (see `.env.example`) and use an environment such as
`development` so the events stay apart from production.

The DSN is public by design for client apps: it only lets a client send events.

## What it sends

- Errors only: `tracesSampleRate` is 0, so no performance tracing (keeps us in the free quota).
- No personal data: `sendDefaultPii` is false (Ley 1581 de 2012). Do not attach user
  names, phone numbers or addresses to events by hand either.

## The release

The release is the app's version constant (`requesterAppVersion`, `providerAppVersion`
in `config.dart`). Each app has a `test/version_test.dart` that fails when the constant
drifts from `version` in its `pubspec.yaml`, so bump both together.
