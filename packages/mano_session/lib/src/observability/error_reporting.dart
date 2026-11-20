import 'package:mano_data/mano_data.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// How Sentry is started; tests pass a fake.
typedef SentryInit = Future<void> Function(
  FlutterOptionsConfiguration configure, {
  AppRunner? appRunner,
});

/// Runs [app] under Sentry when [config] has a DSN: errors only, no personal data (free quota, Ley 1581).
Future<void> runWithErrorReporting({
  required ManoConfig config,
  required String release,
  required void Function() app,
  SentryInit init = SentryFlutter.init,
}) async {
  final dsn = config.sentryDsn;
  if (dsn == null) return app();
  await init(
    (options) => options
      ..dsn = dsn
      ..environment = config.sentryEnvironment
      ..release = release
      ..sendDefaultPii = false
      ..tracesSampleRate = 0,
    appRunner: app,
  );
}
