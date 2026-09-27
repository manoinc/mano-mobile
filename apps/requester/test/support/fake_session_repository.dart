import 'package:mano_session/mano_session.dart';

/// Mirrors `_FakeSessionRepository` in mano_session's own tests: every
/// outcome is injectable, and anything not injected is the ordinary one.
final class FakeSessionRepository implements SessionRepository {
  FakeSessionRepository({this.onRestore, this.onSignIn});

  final Future<Result<Session?, AuthFailure>> Function()? onRestore;
  final Future<Result<Session, AuthFailure>> Function()? onSignIn;

  @override
  Future<Result<Session?, AuthFailure>> restore() async =>
      onRestore?.call() ?? const Ok(null);

  @override
  Future<Result<Session, AuthFailure>> signIn() async =>
      onSignIn?.call() ?? const Err(SignInCancelled());

  @override
  Future<Result<Session, AuthFailure>> refresh() async =>
      const Err(SessionExpired());

  @override
  Future<void> signOut() async {}
}

Session fakeSession() => Session(
  user: const AuthenticatedUser(
    subject: 'user-1',
    username: 'mano-test',
    roles: {ManoRole.requester},
  ),
  accessToken: 'access-1',
  expiresAt: DateTime.now().add(const Duration(minutes: 5)),
);
