import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

final _session = Session(
  user: const AuthenticatedUser(subject: 'u-1', roles: {ManoRole.provider}),
  accessToken: 'access-1',
  expiresAt: DateTime.now().add(const Duration(minutes: 5)),
  isNewAccount: true,
);

({ProviderContainer c, InMemoryPasswordlessAuth auth}) _setUp({
  PasswordlessAuth? passwordless,
  SocialAuth? social,
}) {
  final auth = InMemoryPasswordlessAuth(onVerified: () => _session);
  final c = ProviderContainer.test(
    overrides: [
      manoConfigProvider.overrideWithValue(
        const ManoConfig(
          gatewayGraphQlUrl: 'http://gw/graphql',
          appRole: ManoRole.provider,
        ),
      ),
      passwordlessAuthProvider.overrideWithValue(passwordless ?? auth),
      if (social != null) socialAuthProvider.overrideWithValue(social),
    ],
  );
  c.listen(phoneSignInProvider, (_, _) {});
  return (c: c, auth: auth);
}

PhoneSignInNotifier _n(ProviderContainer c) =>
    c.read(phoneSignInProvider.notifier);

PhoneSignInState _s(ProviderContainer c) => c.read(phoneSignInProvider);

final class _Refusing implements PasswordlessAuth {
  @override
  Future<Result<OtpChallenge, AuthFailure>> sendCode(
    String phone, {
    required String role,
  }) async => const Err(AuthUnavailable(detail: 'down'));

  @override
  Future<Result<OtpChallenge, AuthFailure>> resend(OtpChallenge c) async =>
      const Err(CodeExpired());

  @override
  Future<Result<Session, AuthFailure>> verify(OtpChallenge c, String code) =>
      throw UnimplementedError();
}

void main() {
  test('starts on an empty number', () {
    final (:c, auth: _) = _setUp();

    expect(_s(c).phone, '');
    expect(_s(c).challenge, isNull);
    expect(_s(c).canSend, isFalse);
  });

  test('a number that is not a Colombian mobile is not sent', () async {
    final (:c, :auth) = _setUp();
    _n(c).editPhone('123');

    await _n(c).sendCode();

    expect(auth.sends, 0);
    expect(_s(c).showPhoneProblem, isTrue);
    expect(_s(c).challenge, isNull);
  });

  test('sends the number in E.164 with the app role', () async {
    final (:c, :auth) = _setUp();
    _n(c).editPhone('300 123 4567');

    expect(_s(c).canSend, isTrue);
    await _n(c).sendCode();

    expect(auth.lastRole, ManoRole.provider);
    expect(_s(c).challenge?.phone, '+573001234567');
    expect(_s(c).busy, isFalse);
  });

  test('a send that fails keeps the number and says why', () async {
    final (:c, auth: _) = _setUp(passwordless: _Refusing());
    _n(c).editPhone('3001234567');

    await _n(c).sendCode();

    expect(_s(c).challenge, isNull);
    expect(_s(c).failure, isA<AuthUnavailable>());
    expect(_s(c).phone, '3001234567');
  });

  test('a wrong code says so and returns no session', () async {
    final (:c, auth: _) = _setUp();
    _n(c).editPhone('3001234567');
    await _n(c).sendCode();
    _n(c).editCode('000000');

    final session = await _n(c).verify();

    expect(session, isNull);
    expect(_s(c).failure, isA<InvalidCode>());
  });

  test('typing again clears the failure', () async {
    final (:c, auth: _) = _setUp();
    _n(c).editPhone('3001234567');
    await _n(c).sendCode();
    _n(c).editCode('000000');
    await _n(c).verify();

    _n(c).editCode('1');

    expect(_s(c).failure, isNull);
  });

  test('the right code hands back the session', () async {
    final (:c, auth: _) = _setUp();
    _n(c).editPhone('3001234567');
    await _n(c).sendCode();
    _n(c).editCode('123456');

    final session = await _n(c).verify();

    expect(session, _session);
    expect(_s(c).busy, isFalse);
  });

  test('an incomplete code is not sent', () async {
    final (:c, auth: _) = _setUp();
    _n(c).editPhone('3001234567');
    await _n(c).sendCode();
    _n(c).editCode('123');

    expect(_s(c).canVerify, isFalse);
    expect(await _n(c).verify(), isNull);
    expect(_s(c).failure, isNull);
  });

  test(
    'resend asks again for the same challenge and clears the code',
    () async {
      final (:c, :auth) = _setUp();
      _n(c).editPhone('3001234567');
      await _n(c).sendCode();
      _n(c).editCode('99');

      await _n(c).resend();

      expect(auth.sends, 2);
      expect(_s(c).code, '');
    },
  );

  test(
    'changing the number drops the challenge but keeps the number',
    () async {
      final (:c, auth: _) = _setUp();
      _n(c).editPhone('3001234567');
      await _n(c).sendCode();

      _n(c).changeNumber();

      expect(_s(c).challenge, isNull);
      expect(_s(c).phone, '3001234567');
    },
  );

  group('social sign-in', () {
    test('hands back the session and asks with the app role', () async {
      final social = InMemorySocialAuth(onSignIn: () => Ok(_session));
      final (:c, auth: _) = _setUp(social: social);

      final session = await _n(c).signInWith(SocialProvider.google);

      expect(session, _session);
      expect(social.lastRole, ManoRole.provider);
      expect(social.lastProvider, SocialProvider.google);
      expect(_s(c).busy, isFalse);
    });

    test('closing the sheet says nothing', () async {
      final (:c, auth: _) = _setUp(social: InMemorySocialAuth());

      expect(await _n(c).signInWith(SocialProvider.apple), isNull);
      expect(_s(c).failure, isNull);
    });

    test('a failure is kept to show', () async {
      final (:c, auth: _) = _setUp(
        social: InMemorySocialAuth(
          onSignIn: () => const Err(AuthUnavailable(detail: 'no client')),
        ),
      );

      expect(await _n(c).signInWith(SocialProvider.google), isNull);
      expect(_s(c).failure, isA<AuthUnavailable>());
    });
  });

  test('a shown failure can be dismissed', () async {
    final (:c, auth: _) = _setUp(passwordless: _Refusing());
    _n(c).editPhone('3001234567');
    await _n(c).sendCode();

    _n(c).acknowledgeFailure();

    expect(_s(c).failure, isNull);
  });

  test('starts clean once nobody is looking', () async {
    final c = ProviderContainer.test(
      overrides: [
        passwordlessAuthProvider.overrideWithValue(
          InMemoryPasswordlessAuth(onVerified: () => _session),
        ),
      ],
    );
    final sub = c.listen(phoneSignInProvider, (_, _) {});
    c.read(phoneSignInProvider.notifier).editPhone('3001234567');

    sub.close();
    await c.pump();

    expect(c.read(phoneSignInProvider).phone, '');
  });
}
