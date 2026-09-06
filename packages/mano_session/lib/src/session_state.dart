import 'package:mano_domain/mano_domain.dart';

/// Where the user stands with respect to being signed in.
///
/// Note what this is *not*: it is not `AsyncValue<Session?>`. A failed
/// sign-in is a perfectly ordinary outcome, so it belongs in the state as
/// data. Putting it in `AsyncValue.error` would conflate "the password was
/// wrong" with "this app has a bug", and the interface would end up rendering
/// a crash screen at somebody who simply mistyped.
///
/// So the rule holds all the way to the top: `AsyncError` here means a
/// programming mistake, never a modelled failure.
sealed class SessionState {
  const SessionState();
}

/// Nobody is signed in.
///
/// [lastFailure] is set when the previous attempt failed and the user has not
/// yet been told, so a screen can show it once and move on.
final class SignedOut extends SessionState {
  const SignedOut({this.lastFailure});

  final AuthFailure? lastFailure;
}

/// Somebody is signed in, and the backend has vouched for who they are.
final class SignedIn extends SessionState {
  const SignedIn(this.session);

  final Session session;

  AuthenticatedUser get user => session.user;
}
