import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

void main() {
  final credentials = Credentials(email: 'ana@mano.co', password: 'secret');

  test('defaults to the ordinary outcomes', () async {
    final repository = InMemorySessionRepository();

    expect(await repository.restore(), const Ok<Session?, AuthFailure>(null));
    expect((await repository.signIn(credentials) as Err).failure, isA<SignInCancelled>());
    expect((await repository.refresh() as Err).failure, isA<SessionExpired>());
  });

  test('records what it was asked to do', () async {
    final repository = InMemorySessionRepository();

    await repository.signUp(credentials);
    await repository.signOut();

    expect(repository.lastCredentials, credentials);
    expect(repository.signOutCalls, 1);
  });

  test('plays back injected outcomes', () async {
    final session = Session(
      user: const AuthenticatedUser(subject: 'u', roles: {}),
      accessToken: 'a',
      expiresAt: DateTime.utc(2030),
    );
    final repository = InMemorySessionRepository(
      onSignIn: () async => Ok(session),
      onRefresh: () async => Ok(session),
    );

    expect(await repository.signIn(credentials), Ok<Session, AuthFailure>(session));
    expect(await repository.refresh(), Ok<Session, AuthFailure>(session));
  });
}
