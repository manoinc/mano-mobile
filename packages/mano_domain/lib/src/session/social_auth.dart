import '../result.dart';
import 'auth_failure.dart';
import 'session.dart';

enum SocialProvider { google, apple }

/// Sign in or up with the platform's identity; new accounts get [role].
abstract interface class SocialAuth {
  /// Closing the provider's sheet is [SignInCancelled].
  Future<Result<Session, AuthFailure>> signIn(
    SocialProvider provider, {
    required String role,
  });
}
