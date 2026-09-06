import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_client.dart';
import 'oidc_client.dart';
import 'token_store.dart';

/// The real [SessionRepository]: OIDC for credentials, the gateway for
/// identity, the keystore for persistence.
///
/// Every collaborator arrives through the constructor as an interface, so this
/// class can be exercised in an ordinary unit test with three fakes and no
/// device.
///
/// Its job is translation. Below it, things fail in the vocabulary of
/// transports and platform channels; above it, the domain speaks only
/// [AuthFailure]. Nothing from `flutter_appauth` or `http` escapes upward.
final class OidcSessionRepository implements SessionRepository {
  const OidcSessionRepository({
    required OidcClient oidcClient,
    required GatewayClient gatewayClient,
    required TokenStore tokenStore,
  }) : _oidc = oidcClient,
       _gateway = gatewayClient,
       _store = tokenStore;

  final OidcClient _oidc;
  final GatewayClient _gateway;
  final TokenStore _store;

  @override
  Future<Result<Session, AuthFailure>> signIn() async {
    try {
      final tokens = await _oidc.authorize();
      return await _establish(tokens);
    } on OidcCancelled {
      return const Err(SignInCancelled());
    } on OidcFailed catch (error) {
      return Err(_fromOidc(error));
    }
  }

  @override
  Future<Result<Session?, AuthFailure>> restore() async {
    final refreshToken = await _store.read();
    // Nobody was signed in. An ordinary first launch, not a failure.
    if (refreshToken == null) {
      return const Ok(null);
    }

    final result = await _renew(refreshToken);
    return switch (result) {
      Ok(:final value) => Ok<Session?, AuthFailure>(value),
      Err(:final failure) => Err<Session?, AuthFailure>(failure),
    };
  }

  @override
  Future<Result<Session, AuthFailure>> refresh() async {
    final refreshToken = await _store.read();
    if (refreshToken == null) {
      return const Err(SessionExpired());
    }
    return _renew(refreshToken);
  }

  @override
  Future<void> signOut() async {
    // Reports no failure by design. From the user's point of view signing out
    // has to work, so local credentials are discarded whether or not the
    // provider can be told about it.
    await _store.clear();
  }

  Future<Result<Session, AuthFailure>> _renew(String refreshToken) async {
    try {
      final tokens = await _oidc.refresh(refreshToken);
      return await _establish(tokens);
    } on OidcCancelled {
      return const Err(SessionExpired());
    } on OidcFailed catch (error) {
      if (!error.recoverable) {
        // The grant is gone for good; the stored token is now worthless and
        // keeping it would mean retrying this on every launch.
        await _store.clear();
        return const Err(SessionExpired());
      }
      return Err(_fromOidc(error));
    }
  }

  /// Turns freshly issued credentials into a session, asking the gateway who
  /// they belong to rather than reading the token itself.
  Future<Result<Session, AuthFailure>> _establish(OidcTokens tokens) async {
    try {
      final user = await _gateway.me(tokens.accessToken);

      final refreshToken = tokens.refreshToken;
      if (refreshToken != null) {
        await _store.write(refreshToken);
      }

      return Ok(
        Session(
          user: user,
          accessToken: tokens.accessToken,
          expiresAt: tokens.expiresAt,
        ),
      );
    } on GatewayUnauthorized catch (error) {
      // The provider issued a credential the gateway will not accept. In
      // practice this is nearly always a misconfiguration -- an issuer that
      // does not match, or a client with no audience mapper -- so the detail
      // is worth keeping even though the user never sees it.
      return Err(SignInRejected(reason: error.detail));
    } on GatewayUnavailable catch (error) {
      return Err(AuthUnavailable(detail: error.detail));
    }
  }

  AuthFailure _fromOidc(OidcFailed error) => error.recoverable
      ? AuthUnavailable(detail: error.detail)
      : const SessionExpired();
}
