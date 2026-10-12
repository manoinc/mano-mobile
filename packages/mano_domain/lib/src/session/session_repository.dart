import '../result.dart';
import 'auth_failure.dart';
import 'credentials.dart';
import 'session.dart';

/// The port through which the app signs a user in and keeps them signed in.
///
/// The domain states what it needs; it does not state how. Nothing here
/// mentions SuperTokens, HTTP or secure storage — an
/// implementation is free to use all of those, or none of them. `mano_data`
/// provides the real one; tests provide a fake in three lines.
///
/// Every method returns a [Result] rather than throwing, because every failure
/// listed in [AuthFailure] is one the caller is expected to handle. An
/// implementation may still throw an [Error] when *it* is broken — a malformed
/// response, a violated invariant — and that must not be caught here.
abstract interface class SessionRepository {
  /// Signs an existing account in; wrong details are [SignInRejected].
  Future<Result<Session, AuthFailure>> signIn(Credentials credentials);

  /// Creates an account and signs it in; a taken email is [SignInRejected].
  Future<Result<Session, AuthFailure>> signUp(Credentials credentials);

  /// Restores a session persisted from a previous run, if there is one.
  ///
  /// Returns `Ok(null)` when nobody was signed in — an ordinary first launch,
  /// not a failure. Returns [Err] only when a session existed and could not be
  /// recovered.
  Future<Result<Session?, AuthFailure>> restore();

  /// Renews an expiring credential without troubling the user.
  ///
  /// Returns [SessionExpired] when renewal is no longer possible and the user
  /// has to sign in again.
  Future<Result<Session, AuthFailure>> refresh();

  /// Ends the session and forgets anything persisted about it.
  ///
  /// Signing out must succeed from the user's point of view even if the
  /// provider cannot be reached, so this reports no failure: local credentials
  /// are discarded regardless.
  Future<void> signOut();
}
