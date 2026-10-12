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
const ManoConfig providerConfig = ManoConfig(
  gatewayGraphQlUrl: String.fromEnvironment(
    'MANO_GATEWAY',
    defaultValue: 'http://localhost:8082/graphql',
  ),
  authApiDomain: bool.hasEnvironment('SUPERTOKENS_API_DOMAIN')
      ? String.fromEnvironment('SUPERTOKENS_API_DOMAIN')
      : null,
);
