import 'package:sentry_flutter/sentry_flutter.dart';

/// How Sentry is started; tests pass a fake.
typedef SentryInit = Future<void> Function(
  FlutterOptionsConfiguration configure, {
  AppRunner? appRunner,
});

/// Runs [app] under Sentry when [dsn] is set: errors only, no personal data (free quota, Ley 1581).
Future<void> runWithErrorReporting({
  required String? dsn,
  required String environment,
  required String release,
  required void Function() app,
  SentryInit init = SentryFlutter.init,
}) async {
  if (dsn == null || dsn.isEmpty) return app();
  await init(
    (options) => options
      ..dsn = dsn
      ..environment = environment
      ..release = release
      ..sendDefaultPii = false
      ..tracesSampleRate = 0,
    appRunner: app,
  );
}
