import 'package:mano_domain/mano_domain.dart';

typedef SessionOutcome<T> = Future<Result<T, AuthFailure>> Function();

/// A scriptable [SessionRepository] for tests and offline builds.
final class InMemorySessionRepository implements SessionRepository {
  InMemorySessionRepository({
    this.onRestore,
    this.onSignIn,
    this.onSignUp,
    this.onRefresh,
  });

  final SessionOutcome<Session?>? onRestore;
  final SessionOutcome<Session>? onSignIn;
  final SessionOutcome<Session>? onSignUp;
  final SessionOutcome<Session>? onRefresh;

  Credentials? lastCredentials;
  int signOutCalls = 0;

  @override
  Future<Result<Session?, AuthFailure>> restore() async =>
      onRestore?.call() ?? const Ok(null);

  @override
  Future<Result<Session, AuthFailure>> signIn(Credentials credentials) async {
    lastCredentials = credentials;
    return onSignIn?.call() ?? const Err(SignInCancelled());
  }

  @override
  Future<Result<Session, AuthFailure>> signUp(Credentials credentials) async {
    lastCredentials = credentials;
    return onSignUp?.call() ?? const Err(SignInCancelled());
  }

  @override
  Future<Result<Session, AuthFailure>> refresh() async =>
      onRefresh?.call() ?? const Err(SessionExpired());

  @override
  Future<void> signOut() async => signOutCalls++;
}
