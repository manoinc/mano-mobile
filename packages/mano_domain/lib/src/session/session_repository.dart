import '../result.dart';
import 'auth_failure.dart';
import 'session.dart';

/// The port through which the app signs a user in and keeps them signed in.
///
/// The domain states what it needs; it does not state how. Nothing here
/// mentions OAuth, Keycloak, PKCE, browsers or secure storage — an
/// implementation is free to use all of those, or none of them. `mano_data`
/// provides the real one; tests provide a fake in three lines.
///
/// Every method returns a [Result] rather than throwing, because every failure
/// listed in [AuthFailure] is one the caller is expected to handle. An
/// implementation may still throw an [Error] when *it* is broken — a malformed
/// response, a violated invariant — and that must not be caught here.
abstract interface class SessionRepository {
  /// Signs a user in, interactively if the implementation needs to.
  ///
  /// Returns [SignInCancelled] rather than an error when the user simply backs
  /// out, so the interface can tell "changed their mind" from "was refused".
  Future<Result<Session, AuthFailure>> signIn();

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
