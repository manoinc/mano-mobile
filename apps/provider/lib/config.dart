import 'package:mano_session/mano_session.dart';

/// This app's view of Mano's services.
///
/// Defaults point at a local development stack reached through `adb reverse`,
/// and every value can be replaced at build time:
///
/// ```bash
/// flutter run --dart-define=MANO_ISSUER=https://accounts.mano.co/realms/mano \
///             --dart-define=MANO_GATEWAY=https://api.mano.co/graphql \
///             --dart-define=MANO_ALLOW_INSECURE=false
/// ```
const ManoConfig providerConfig = ManoConfig(
  issuer: String.fromEnvironment(
    'MANO_ISSUER',
    defaultValue: 'http://localhost:8080/realms/mano',
  ),

  // The Proveedor app authenticates as its own OIDC client, separate from
  // the Solicitante app and from the gateway. It still needs an audience mapper
  // for `mano-gateway` in Keycloak, or the tokens it receives carry no `aud`
  // and the gateway refuses them.
  clientId: String.fromEnvironment(
    'MANO_CLIENT_ID',
    defaultValue: 'mano-provider-app',
  ),

  // Must also be registered as a valid redirect URI on the Keycloak client,
  // and matches the manifestPlaceholder in android/app/build.gradle.kts.
  redirectUrl: String.fromEnvironment(
    'MANO_REDIRECT_URL',
    defaultValue: 'com.manoinc.mano.provider:/oauth2redirect',
  ),

  gatewayGraphQlUrl: String.fromEnvironment(
    'MANO_GATEWAY',
    defaultValue: 'http://localhost:8082/graphql',
  ),

  // True only because local development talks to Keycloak over plain HTTP on
  // localhost. Set to false for anything a real user touches.
  allowInsecureConnections: bool.fromEnvironment(
    'MANO_ALLOW_INSECURE',
    defaultValue: true,
  ),
);
