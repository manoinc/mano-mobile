/// Where this build of the app finds Mano's services.
///
/// Passed in at composition time rather than read from a global, so a test, a
/// staging build and a production build differ by a value instead of by a
/// conditional buried somewhere.
final class ManoConfig {
  const ManoConfig({
    required this.issuer,
    required this.clientId,
    required this.redirectUrl,
    required this.gatewayGraphQlUrl,
    this.scopes = const ['openid', 'profile', 'email', 'offline_access'],
    this.allowInsecureConnections = false,
  });

  /// The realm's issuer URL, exactly as it appears in a token's `iss` claim.
  ///
  /// This must match what `mano-gateway` was configured with, character for
  /// character. The gateway compares the two exactly, so reaching Keycloak by
  /// a different host -- a LAN address, or the Android emulator's `10.0.2.2`
  /// alias -- produces tokens it will refuse.
  final String issuer;

  /// The OIDC client this app authenticates as.
  ///
  /// The two apps use different clients, but both must carry an audience
  /// mapper for `mano-gateway`: Keycloak omits `aud` unless one is configured,
  /// and the gateway rejects a token that claims no audience.
  final String clientId;

  /// Where the authorization server sends the user back after sign-in.
  ///
  /// A custom scheme registered by the app, e.g.
  /// `com.manoinc.mano.requester:/oauth2redirect`, and it must be listed on
  /// the Keycloak client or the redirect is refused.
  final String redirectUrl;

  /// The GraphQL endpoint of `mano-gateway`.
  final String gatewayGraphQlUrl;

  /// Scopes requested at sign-in.
  ///
  /// `offline_access` is what earns a refresh token; without it the user is
  /// sent back to the browser every few minutes.
  final List<String> scopes;

  /// Whether AppAuth may talk to the authorization server over plain HTTP.
  ///
  /// Necessary only for local development, where Keycloak is reached at
  /// `http://localhost:8080` through `adb reverse`. AppAuth refuses cleartext
  /// by default, and that default is correct: over a real network an
  /// unencrypted token exchange is readable by anyone on the path.
  ///
  /// Must be `false` in anything that reaches a real user.
  final bool allowInsecureConnections;
}
