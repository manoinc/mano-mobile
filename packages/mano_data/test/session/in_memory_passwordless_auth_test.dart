import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

void main() {
  final session = Session(
    user: const AuthenticatedUser(subject: 'u1', roles: {'requester'}),
    accessToken: 't',
    expiresAt: DateTime(2030),
  );

  test('sends a code to the number and remembers the role', () async {
    final auth = InMemoryPasswordlessAuth(onVerified: () => session);

    final challenge = (await auth.sendCode(
      '+573001234567',
      role: 'requester',
    )).valueOrNull!;

    expect(challenge.phone, '+573001234567');
    expect(auth.lastRole, 'requester');
  });

  test('the right code signs in; a wrong one counts down', () async {
    final auth = InMemoryPasswordlessAuth(onVerified: () => session);
    final challenge = (await auth.sendCode(
      '+573001234567',
      role: 'requester',
    )).valueOrNull!;

    expect(
      (await auth.verify(challenge, '000000')).failureOrNull,
      isA<InvalidCode>().having((f) => f.attemptsLeft, 'left', 2),
    );
    expect((await auth.verify(challenge, '123456')).valueOrNull, session);
  });

  test('three wrong codes lock it', () async {
    final auth = InMemoryPasswordlessAuth(onVerified: () => session);
    final challenge = (await auth.sendCode(
      '+573001234567',
      role: 'requester',
    )).valueOrNull!;

    for (var i = 0; i < 3; i++) {
      await auth.verify(challenge, '000000');
    }

    expect(
      (await auth.verify(challenge, '123456')).failureOrNull,
      isA<TooManyAttempts>(),
    );
  });

  test('social sign-in is scripted and remembers the provider', () async {
    final auth = InMemorySocialAuth(onSignIn: () => Ok(session));

    final result = await auth.signIn(SocialProvider.apple, role: 'provider');

    expect(result.valueOrNull, session);
    expect(auth.lastProvider, SocialProvider.apple);
    expect(auth.lastRole, 'provider');
  });
}
