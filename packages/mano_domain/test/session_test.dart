import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

AuthenticatedUser userWith(Set<String> roles) =>
    AuthenticatedUser(subject: 'user-1', username: 'tester', roles: roles);

void main() {
  group('AuthenticatedUser', () {
    test('reports a granted role', () {
      expect(userWith({ManoRole.provider}).hasRole(ManoRole.provider), isTrue);
    });

    test('role matching is case-sensitive', () {
      // Role names are case-sensitive, and treating 'Provider' as 'provider'
      // would quietly widen every check built on this.
      expect(userWith({'provider'}).hasRole('Provider'), isFalse);
    });

    test('hasAnyRole needs one match, and nothing satisfies an empty set', () {
      final user = userWith({ManoRole.provider});

      expect(user.hasAnyRole({ManoRole.requester, ManoRole.provider}), isTrue);
      expect(user.hasAnyRole({ManoRole.requester}), isFalse);
      expect(user.hasAnyRole(const <String>{}), isFalse);
    });

    test('hasAllRoles needs every match, and an empty set is vacuous', () {
      final both = userWith({ManoRole.requester, ManoRole.provider});

      expect(both.hasAllRoles({ManoRole.requester, ManoRole.provider}), isTrue);
      expect(both.hasAllRoles({ManoRole.provider, 'verified'}), isFalse);
      expect(both.hasAllRoles(const <String>{}), isTrue);
    });

    test('the two sides of the marketplace are distinguishable', () {
      expect(userWith({ManoRole.requester}).isRequester, isTrue);
      expect(userWith({ManoRole.requester}).isProvider, isFalse);
      expect(userWith({ManoRole.provider}).isProvider, isTrue);
    });

    test('displayName falls back until it finds something', () {
      expect(
        const AuthenticatedUser(
          subject: 's',
          username: 'handle',
          email: 'e@x.test',
          roles: {},
        ).displayName,
        'handle',
      );
      expect(
        const AuthenticatedUser(
          subject: 's',
          email: 'e@x.test',
          roles: {},
        ).displayName,
        'e@x.test',
      );
      expect(const AuthenticatedUser(subject: 's', roles: {}).displayName, 's');
    });
  });

  group('Session', () {
    final issued = DateTime.utc(2026, 1, 1, 12);

    Session sessionExpiringAt(DateTime at) => Session(
      user: userWith({ManoRole.provider}),
      accessToken: 'token',
      expiresAt: at,
    );

    test('is not expired before its expiry', () {
      final session = sessionExpiringAt(issued.add(const Duration(minutes: 5)));

      expect(session.isExpired(now: issued), isFalse);
    });

    test('is expired at and after its expiry', () {
      final session = sessionExpiringAt(issued);

      expect(session.isExpired(now: issued), isTrue);
      expect(
        session.isExpired(now: issued.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('flags a credential worth renewing before the next call', () {
      final session = sessionExpiringAt(
        issued.add(const Duration(seconds: 30)),
      );

      expect(
        session.expiresWithin(const Duration(minutes: 1), now: issued),
        isTrue,
      );
      expect(
        session.expiresWithin(const Duration(seconds: 10), now: issued),
        isFalse,
      );
    });

    test('does not put the access token in its string form', () {
      // Sessions reach logs and crash reports. The credential must not.
      final session = sessionExpiringAt(issued);

      expect(session.toString(), isNot(contains('token')));
    });
  });

  group('AuthFailure', () {
    test('every case carries a message fit to show a user', () {
      const failures = <AuthFailure>[
        SignInRejected(),
        SignInCancelled(),
        SessionExpired(),
        AuthUnavailable(),
        WrongCredentials(),
        EmailAlreadyRegistered(),
        InvalidCode(),
        CodeExpired(),
        TooManyAttempts(),
      ];

      for (final failure in failures) {
        expect(failure.message, isNotEmpty, reason: '$failure');
      }
    });

    test('operational detail stays out of the user-facing message', () {
      const failure = AuthUnavailable(detail: 'SocketException: port 8080');

      expect(failure.message, isNot(contains('SocketException')));
      expect(failure.toString(), contains('SocketException'));
    });

    test('cancelling is distinguishable from being refused', () {
      // The interface must not show an error when the user simply backed out.
      const AuthFailure failure = SignInCancelled();

      final isCancellation = switch (failure) {
        SignInCancelled() => true,
        SignInRejected() ||
        SessionExpired() ||
        AuthUnavailable() ||
        WrongCredentials() ||
        EmailAlreadyRegistered() ||
        InvalidCode() ||
        CodeExpired() ||
        TooManyAttempts() => false,
      };

      expect(isCancellation, isTrue);
    });
  });
}
