/// What can go wrong while establishing or restoring a session, expressed in
/// terms the app can act on.
///
/// This mirrors `AuthError` in `libmano-backapp`, and for the same reason: a
/// caller must be able to tell *"this person is not allowed in"* from *"we
/// could not even ask"* without knowing which provider, if any, is behind the
/// port. The two demand opposite responses — one asks the user to try again,
/// the other asks them to wait while somebody is paged.
///
/// Deliberately absent: anything describing a bug. A malformed response, a
/// null where there should not be one, an unreachable branch — those are
/// [Error]s, thrown and never caught, not failures to be modelled here.
sealed class AuthFailure {
  const AuthFailure();

  /// A short, non-technical description, suitable for showing a user.
  String get message;
}

/// The provider refused the attempt for a reason not modelled elsewhere.
final class SignInRejected extends AuthFailure {
  const SignInRejected({this.reason});

  /// What the provider said, when it said anything useful. Not for display.
  final String? reason;

  @override
  String get message => 'Those sign-in details were not accepted.';

  @override
  String toString() => 'SignInRejected(reason: $reason)';
}

/// Sign-in found no account with that email and password.
final class WrongCredentials extends AuthFailure {
  const WrongCredentials();

  @override
  String get message => 'That email and password do not match an account.';

  @override
  String toString() => 'WrongCredentials()';
}

/// Sign-up was refused because an account already uses that email.
final class EmailAlreadyRegistered extends AuthFailure {
  const EmailAlreadyRegistered();

  @override
  String get message => 'An account already uses that email. Sign in instead.';

  @override
  String toString() => 'EmailAlreadyRegistered()';
}

/// The user closed the sign-in screen without finishing.
///
/// Distinct from [SignInRejected] because nothing went wrong: the interface
/// should return quietly to where it was, not show an error.
final class SignInCancelled extends AuthFailure {
  const SignInCancelled();

  @override
  String get message => 'Sign-in was cancelled.';

  @override
  String toString() => 'SignInCancelled()';
}

/// There was a session, but it has expired and could not be renewed.
final class SessionExpired extends AuthFailure {
  const SessionExpired();

  @override
  String get message => 'Your session has expired. Please sign in again.';

  @override
  String toString() => 'SessionExpired()';
}

/// The authentication system could not be reached or failed on its own side.
///
/// Not the user's fault, and not something they can fix by re-entering
/// anything. The interface should say so and offer to retry.
final class AuthUnavailable extends AuthFailure {
  const AuthUnavailable({this.detail});

  /// Operational detail worth logging. Never show this to a user.
  final String? detail;

  @override
  String get message =>
      'We cannot reach the sign-in service right now. Please try again shortly.';

  @override
  String toString() => 'AuthUnavailable(detail: $detail)';
}
