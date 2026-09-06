
/// The credentials an authorization server hands back.
final class OidcTokens {
  const OidcTokens({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.idToken,
  });

  final String accessToken;
  final DateTime expiresAt;
  final String? refreshToken;
  final String? idToken;

  // Deliberately omits every credential: these end up in logs.
  @override
  String toString() => 'OidcTokens(expiresAt: $expiresAt)';
}

/// Raised when the user closes the sign-in screen without finishing.
final class OidcCancelled implements Exception {
  const OidcCancelled();
}

/// Raised when the authorization server refuses, or cannot be reached.
final class OidcFailed implements Exception {
  const OidcFailed(this.detail, {this.recoverable = true});

  final String detail;

  /// Whether trying again might work. `false` means the credentials or grant
  /// are gone for good and the user has to sign in afresh.
  final bool recoverable;

  @override
  String toString() => 'OidcFailed($detail, recoverable: $recoverable)';
}

/// The OAuth exchange, behind an interface.
///
/// `flutter_appauth` is a concrete class backed by platform channels, so code
/// depending on it directly can only be tested on a device. Naming the two
/// operations we actually use lets [SessionRepository] implementations be
/// exercised with a fake, in an ordinary unit test.
abstract interface class OidcClient {
  /// Runs the interactive authorization-code flow with PKCE.
  Future<OidcTokens> authorize();

  /// Exchanges a refresh token for a fresh access token.
  Future<OidcTokens> refresh(String refreshToken);
}
