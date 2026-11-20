import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

ManoConfig _config({String? dsn}) => ManoConfig(
  gatewayGraphQlUrl: 'http://gw/graphql',
  appRole: ManoRole.requester,
  sentryDsn: dsn,
  sentryEnvironment: 'production',
);

void main() {
  test('without a DSN the app runs and Sentry is never started', () async {
    var ran = false;
    var initCalls = 0;

    await runWithErrorReporting(
      config: _config(),
      release: 'mano-requester@1.0.0',
      app: () => ran = true,
      init: (configure, {appRunner}) async => initCalls++,
    );

    expect(ran, isTrue);
    expect(initCalls, 0);
  });

  test(
    'with a DSN, Sentry wraps the app: errors only, no personal data',
    () async {
      var ran = false;
      final options = SentryFlutterOptions();

      await runWithErrorReporting(
        config: _config(dsn: 'https://key@o1.ingest.us.sentry.io/2'),
        release: 'mano-requester@1.0.0',
        app: () => ran = true,
        init: (configure, {appRunner}) async {
          await configure(options);
          await appRunner?.call();
        },
      );

      expect(ran, isTrue);
      expect(options.dsn, 'https://key@o1.ingest.us.sentry.io/2');
      expect(options.environment, 'production');
      expect(options.release, 'mano-requester@1.0.0');
      expect(options.sendDefaultPii, isFalse);
      expect(options.tracesSampleRate, 0);
    },
  );
}
