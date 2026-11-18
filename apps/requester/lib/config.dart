import 'package:mano_session/mano_session.dart';

/// This app's view of Mano's services.
///
/// Defaults point at the local gateway reached through `adb reverse`, and can
/// be replaced at build time:
///
/// ```bash
/// flutter run --dart-define=MANO_GATEWAY=https://api.mano.co/graphql
/// ```
///
/// Sign-in is off unless a SuperTokens API domain is given:
///
/// ```bash
/// flutter run --dart-define=SUPERTOKENS_API_DOMAIN=http://localhost:3001
/// ```
const ManoConfig requesterConfig = ManoConfig(
  gatewayGraphQlUrl: String.fromEnvironment(
    'MANO_GATEWAY',
    defaultValue: 'http://localhost:8082/graphql',
  ),
  appRole: ManoRole.requester,
  authApiDomain: bool.hasEnvironment('SUPERTOKENS_API_DOMAIN')
      ? String.fromEnvironment('SUPERTOKENS_API_DOMAIN')
      : null,
  // mano-auth's Google web client ID; absent, Google reports it cannot connect.
  googleServerClientId: bool.hasEnvironment('GOOGLE_SERVER_CLIENT_ID')
      ? String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID')
      : null,
);

/// Shown in Configuración; keep in step with `version` in pubspec.yaml.
const String requesterAppVersion = String.fromEnvironment(
  'MANO_APP_VERSION',
  defaultValue: '0.1.0',
);

/// Sentry's DSN; unset in dev and tests, so nothing is reported.
const String? sentryDsn = bool.hasEnvironment('SENTRY_DSN')
    ? String.fromEnvironment('SENTRY_DSN')
    : null;

/// Which Sentry environment events are filed under.
const String sentryEnvironment = String.fromEnvironment(
  'SENTRY_ENVIRONMENT',
  defaultValue: 'development',
);
