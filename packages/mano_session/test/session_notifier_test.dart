import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

/// The notifier is exercised here with a fake repository and nothing else: no
/// browser, no keystore, no gateway, no `ManoConfig`. That is possible because
/// everything above the adapters depends on [SessionRepository], the
/// interface, and because composition happens in one overridable provider.

final _credentials = Credentials(email: 'ana@mano.co', password: 'secret');

const _user = AuthenticatedUser(
  subject: 'user-1',
  username: 'mano-test',
  roles: {ManoRole.provider},
);

Session session({
  String token = 'access-1',
  Duration lifetime = const Duration(minutes: 5),
}) => Session(
  user: _user,
  accessToken: token,
  expiresAt: DateTime.now().add(lifetime),
);

ProviderContainer containerWith(SessionRepository repository) {
  final container = ProviderContainer.test(
    overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
  );
  return container;
}

void main() {
  test('a cold start with no stored session lands signed out', () async {
    final container = containerWith(InMemorySessionRepository());

    final state = await container.read(sessionProvider.future);

    expect(state, isA<SignedOut>());
    expect((state as SignedOut).lastFailure, isNull);
  });

  test('a restorable session lands signed in', () async {
    final container = containerWith(
      InMemorySessionRepository(onRestore: () async => Ok(session())),
    );

    final state = await container.read(sessionProvider.future);

    expect(state, isA<SignedIn>());
    expect((state as SignedIn).user, _user);
  });

  test('a failed restore is signed out, carrying the reason', () async {
    final container = containerWith(
      InMemorySessionRepository(
        onRestore: () async => const Err(AuthUnavailable(detail: 'down')),
      ),
    );

    final state = await container.read(sessionProvider.future);

    expect(state, isA<SignedOut>());
    expect((state as SignedOut).lastFailure, isA<AuthUnavailable>());
  });

  test('a rejected sign-in stays data, never an error', () async {
    // The distinction this whole design rests on: a user mistyping something
    // must not reach AsyncError, because AsyncError means the app has a bug.
    final container = containerWith(
      InMemorySessionRepository(
        onSignIn: () async => const Err(SignInRejected(reason: '401')),
      ),
    );
    await container.read(sessionProvider.future);

    await container.read(sessionProvider.notifier).signIn(_credentials);

    final state = container.read(sessionProvider);
    expect(state.hasError, isFalse, reason: 'a refused sign-in is not a bug');
    expect(state.value, isA<SignedOut>());
    expect((state.value! as SignedOut).lastFailure, isA<SignInRejected>());
  });

  test('a successful sign-in lands signed in', () async {
    final container = containerWith(
      InMemorySessionRepository(onSignIn: () async => Ok(session())),
    );
    await container.read(sessionProvider.future);

    await container.read(sessionProvider.notifier).signIn(_credentials);

    expect(container.read(sessionProvider).value, isA<SignedIn>());
    expect(container.read(currentUserProvider), _user);
  });

  test('signing out clears the session and tells the repository', () async {
    final repository = InMemorySessionRepository(
      onRestore: () async => Ok(session()),
    );
    final container = containerWith(repository);
    await container.read(sessionProvider.future);

    await container.read(sessionProvider.notifier).signOut();

    expect(container.read(sessionProvider).value, isA<SignedOut>());
    expect(container.read(currentUserProvider), isNull);
    expect(repository.signOutCalls, 1);
  });

  test('an acknowledged failure is not shown twice', () async {
    final container = containerWith(
      InMemorySessionRepository(
        onRestore: () async => const Err(AuthUnavailable()),
      ),
    );
    await container.read(sessionProvider.future);

    container.read(sessionProvider.notifier).acknowledgeFailure();

    expect(
      (container.read(sessionProvider).value! as SignedOut).lastFailure,
      isNull,
    );
  });

  test('currentUser is null unless somebody is signed in', () async {
    final container = containerWith(InMemorySessionRepository());
    await container.read(sessionProvider.future);

    expect(container.read(currentUserProvider), isNull);
  });

  test('keeps the session visible while a sign-in is in flight', () async {
    // If signIn() published a bare AsyncLoading first, state.value would go
    // null for as long as the repository call takes -- and since the app's
    // root screen switches on that value, the whole app would flash back to
    // its own loading screen every time someone tapped the button.
    final gate = Completer<Result<Session, AuthFailure>>();
    final container = containerWith(
      InMemorySessionRepository(onSignIn: () => gate.future),
    );
    await container.read(sessionProvider.future);

    final signingIn = container
        .read(sessionProvider.notifier)
        .signIn(_credentials);
    expect(container.read(sessionProvider).value, isA<SignedOut>());

    gate.complete(Ok(session()));
    await signingIn;
    expect(container.read(sessionProvider).value, isA<SignedIn>());
  });

  group('guests', () {
    test('browsing as a guest is its own state, with no user', () async {
      final container = containerWith(InMemorySessionRepository());
      await container.read(sessionProvider.future);

      container.read(sessionProvider.notifier).browseAsGuest();

      expect(container.read(sessionProvider).value, isA<Guest>());
      expect(container.read(currentUserProvider), isNull);
      expect(container.read(hasAccountProvider), isFalse);
    });

    test('a guest heading for the door is signed out', () async {
      final container = containerWith(InMemorySessionRepository());
      await container.read(sessionProvider.future);
      container.read(sessionProvider.notifier).browseAsGuest();

      container.read(sessionProvider.notifier).leaveGuest();

      expect(container.read(sessionProvider).value, isA<SignedOut>());
    });

    test('leaving is a no-op for somebody signed in', () async {
      final container = containerWith(
        InMemorySessionRepository(onRestore: () async => Ok(session())),
      );
      await container.read(sessionProvider.future);

      container.read(sessionProvider.notifier).leaveGuest();
      container.read(sessionProvider.notifier).browseAsGuest();

      expect(container.read(sessionProvider).value, isA<SignedIn>());
      expect(container.read(hasAccountProvider), isTrue);
    });
  });

  test('signing in passes the credentials to the repository', () async {
    final repository = InMemorySessionRepository(
      onSignIn: () async => Ok(session()),
    );
    final container = containerWith(repository);
    await container.read(sessionProvider.future);

    await container.read(sessionProvider.notifier).signIn(_credentials);

    expect(repository.lastCredentials, _credentials);
  });

  test('signing in reports the failure, or null on success', () async {
    final refused = containerWith(
      InMemorySessionRepository(
        onSignIn: () async => const Err(SignInRejected()),
      ),
    );
    await refused.read(sessionProvider.future);
    expect(
      await refused.read(sessionProvider.notifier).signIn(_credentials),
      isA<SignInRejected>(),
    );

    final accepted = containerWith(
      InMemorySessionRepository(onSignIn: () async => Ok(session())),
    );
    await accepted.read(sessionProvider.future);
    expect(
      await accepted.read(sessionProvider.notifier).signIn(_credentials),
      isNull,
    );
  });

  test('signing up lands signed in', () async {
    final container = containerWith(
      InMemorySessionRepository(onSignUp: () async => Ok(session())),
    );
    await container.read(sessionProvider.future);

    await container.read(sessionProvider.notifier).signUp(_credentials);

    expect(container.read(sessionProvider).value, isA<SignedIn>());
  });

  test('the access token follows the session', () async {
    final container = containerWith(
      InMemorySessionRepository(onRestore: () async => Ok(session())),
    );
    await container.read(sessionProvider.future);

    expect(container.read(accessTokenProvider), 'access-1');

    await container.read(sessionProvider.notifier).signOut();
    expect(container.read(accessTokenProvider), isNull);
  });

  group('fresh access token', () {
    test('hands out the current token while it has time left', () async {
      var refreshes = 0;
      final container = containerWith(
        InMemorySessionRepository(
          onRestore: () async => Ok(session()),
          onRefresh: () async {
            refreshes++;
            return Ok(session(token: 'access-2'));
          },
        ),
      );
      await container.read(sessionProvider.future);

      expect(
        await container.read(sessionProvider.notifier).freshAccessToken(),
        'access-1',
      );
      expect(refreshes, 0);
    });

    test(
      'renews a token about to expire, once for concurrent callers',
      () async {
        var refreshes = 0;
        final container = containerWith(
          InMemorySessionRepository(
            onRestore: () async =>
                Ok(session(lifetime: const Duration(seconds: 30))),
            onRefresh: () async {
              refreshes++;
              return Ok(session(token: 'access-2'));
            },
          ),
        );
        await container.read(sessionProvider.future);
        final manager = container.read(sessionProvider.notifier);

        final tokens = await Future.wait([
          manager.freshAccessToken(),
          manager.freshAccessToken(),
        ]);

        expect(tokens, ['access-2', 'access-2']);
        expect(refreshes, 1);
        expect(container.read(accessTokenProvider), 'access-2');
      },
    );

    test('a refused renewal signs out, saying why', () async {
      final container = containerWith(
        InMemorySessionRepository(
          onRestore: () async =>
              Ok(session(lifetime: const Duration(seconds: 30))),
        ),
      );
      await container.read(sessionProvider.future);

      expect(
        await container.read(sessionProvider.notifier).freshAccessToken(),
        isNull,
      );

      final state = container.read(sessionProvider).value;
      expect(state, isA<SignedOut>());
      expect((state! as SignedOut).lastFailure, isA<SessionExpired>());
    });

    test('an offline renewal keeps using the still-valid token', () async {
      final container = containerWith(
        InMemorySessionRepository(
          onRestore: () async =>
              Ok(session(lifetime: const Duration(seconds: 30))),
          onRefresh: () async => const Err(AuthUnavailable()),
        ),
      );
      await container.read(sessionProvider.future);

      expect(
        await container.read(sessionProvider.notifier).freshAccessToken(),
        'access-1',
      );
      expect(container.read(sessionProvider).value, isA<SignedIn>());
    });

    test('guests have no token', () async {
      final container = containerWith(InMemorySessionRepository());
      await container.read(sessionProvider.future);
      container.read(sessionProvider.notifier).browseAsGuest();

      expect(
        await container.read(sessionProvider.notifier).freshAccessToken(),
        isNull,
      );
    });
  });
}
