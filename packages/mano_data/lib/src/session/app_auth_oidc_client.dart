import 'package:flutter_appauth/flutter_appauth.dart';

import '../config/mano_config.dart';
import 'oidc_client.dart';

/// [OidcClient] backed by AppAuth, which drives the system browser.
///
/// The system browser matters: it means Mano never sees the user's password,
/// and that a session already established in the browser can be reused.
final class AppAuthOidcClient implements OidcClient {
  AppAuthOidcClient(this._config, {FlutterAppAuth? appAuth})
    : _appAuth = appAuth ?? const FlutterAppAuth();

  final ManoConfig _config;
  final FlutterAppAuth _appAuth;

  @override
  Future<OidcTokens> authorize() async {
    try {
      final response = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _config.clientId,
          _config.redirectUrl,
          issuer: _config.issuer,
          scopes: _config.scopes,
          // PKCE is applied by default and must stay that way: these are
          // public clients shipped to devices, so they hold no secret worth
          // the name.
          allowInsecureConnections: _config.allowInsecureConnections,
        ),
      );
      return _toTokens(response);
    } on FlutterAppAuthUserCancelledException {
      throw const OidcCancelled();
    } on FlutterAppAuthPlatformException catch (error) {
      throw OidcFailed('${error.code}: ${error.message}');
    }
  }

  @override
  Future<OidcTokens> refresh(String refreshToken) async {
    try {
      final response = await _appAuth.token(
        TokenRequest(
          _config.clientId,
          _config.redirectUrl,
          issuer: _config.issuer,
          refreshToken: refreshToken,
          scopes: _config.scopes,
          allowInsecureConnections: _config.allowInsecureConnections,
        ),
      );
      return _toTokens(response);
    } on FlutterAppAuthUserCancelledException {
      throw const OidcCancelled();
    } on FlutterAppAuthPlatformException catch (error) {
      // A rejected grant is terminal: the refresh token has been revoked or
      // has expired, and no amount of retrying will change that.
      final terminal =
          error.code.contains('invalid_grant') ||
          (error.message?.contains('invalid_grant') ?? false);
      throw OidcFailed('${error.code}: ${error.message}', recoverable: !terminal);
    }
  }

  OidcTokens _toTokens(TokenResponse response) {
    final accessToken = response.accessToken;
    if (accessToken == null) {
      // Not a modelled failure: a token endpoint that returns 200 with no
      // access token is broken in a way we have no sensible response to.
      throw StateError('the token endpoint returned no access token');
    }

    return OidcTokens(
      accessToken: accessToken,
      // Keycloak always sends expires_in; the fallback only keeps a missing
      // value from being mistaken for "already expired".
      expiresAt:
          response.accessTokenExpirationDateTime ??
          DateTime.now().add(const Duration(minutes: 5)),
      refreshToken: response.refreshToken,
      idToken: response.idToken,
    );
  }
}
