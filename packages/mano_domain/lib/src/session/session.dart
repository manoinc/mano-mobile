import 'authenticated_user.dart';

/// An established sign-in: who the user is, and the credential that proves it
/// to the backend.
final class Session {
  const Session({
    required this.user,
    required this.accessToken,
    required this.expiresAt,
  });

  /// Who the backend says this is.
  final AuthenticatedUser user;

  /// The credential presented to the API on the user's behalf.
  ///
  /// The app never inspects this beyond passing it along. Reading claims out
  /// of a token on the client and acting on them would be decoding, not
  /// verifying — only the backend holds the keys that make the difference.
  final String accessToken;

  /// When [accessToken] stops being accepted.
  final DateTime expiresAt;

  /// Whether the credential has passed its expiry, allowing [now] to be
  /// supplied so this stays testable without waiting.
  bool isExpired({DateTime? now}) =>
      !(now ?? DateTime.now()).isBefore(expiresAt);

  /// Whether the credential expires within [window] and is worth renewing
  /// before the next call rather than after one fails.
  bool expiresWithin(Duration window, {DateTime? now}) =>
      (now ?? DateTime.now()).add(window).isAfter(expiresAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session &&
          user == other.user &&
          accessToken == other.accessToken &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(user, accessToken, expiresAt);

  // Deliberately omits the token: sessions end up in logs and error reports.
  @override
  String toString() => 'Session(user: ${user.subject}, expiresAt: $expiresAt)';
}
