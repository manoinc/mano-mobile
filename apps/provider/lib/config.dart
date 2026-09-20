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
/// Nothing here yet about how a Proveedor signs in — that is still an open
/// decision, and whichever way it lands will add its own configuration here
/// or in a config type of its own.
const ManoConfig providerConfig = ManoConfig(
  gatewayGraphQlUrl: String.fromEnvironment(
    'MANO_GATEWAY',
    defaultValue: 'http://localhost:8082/graphql',
  ),
);
