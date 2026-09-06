import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:mano_session/mano_session.dart';

/// The notifier is exercised here with a fake repository and nothing else: no
/// browser, no keystore, no gateway, no `ManoConfig`. That is possible because
/// everything above the adapters depends on [SessionRepository], the
/// interface, and because composition happens in one overridable provider.

final class _FakeSessionRepository implements SessionRepository {
  _FakeSessionRepository({this.onSignIn, this.onRestore});

  final Future<Result<Session, AuthFailure>> Function()? onSignIn;
  final Future<Result<Session?, AuthFailure>> Function()? onRestore;

  int signOutCalls = 0;

  @override
  Future<Result<Session, AuthFailure>> signIn() async =>
      onSignIn?.call() ?? const Err(SignInCancelled());

  @override
  Future<Result<Session?, AuthFailure>> restore() async =>
      onRestore?.call() ?? const Ok(null);

  @override
  Future<Result<Session, AuthFailure>> refresh() async =>
      const Err(SessionExpired());

  @override
  Future<void> signOut() async => signOutCalls++;
}

const _user = AuthenticatedUser(
  subject: 'user-1',
  username: 'mano-test',
  roles: {ManoRole.provider},
);

Session session() => Session(
  user: _user,
  accessToken: 'access-1',
  expiresAt: DateTime.now().add(const Duration(minutes: 5)),
);

ProviderContainer containerWith(SessionRepository repository) {
  final container = ProviderContainer.test(
    overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
  );
  return container;
}

void main() {
  test('a cold start with no stored session lands signed out', () async {
    final container = containerWith(_FakeSessionRepository());

    final state = await container.read(sessionProvider.future);

    expect(state, isA<SignedOut>());
    expect((state as SignedOut).lastFailure, isNull);
  });

  test('a restorable session lands signed in', () async {
    final container = containerWith(
      _FakeSessionRepository(onRestore: () async => Ok(session())),
    );

    final state = await container.read(sessionProvider.future);

    expect(state, isA<SignedIn>());
    expect((state as SignedIn).user, _user);
  });

  test('a failed restore is signed out, carrying the reason', () async {
    final container = containerWith(
      _FakeSessionRepository(
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
      _FakeSessionRepository(
        onSignIn: () async => const Err(SignInRejected(reason: '401')),
      ),
    );
    await container.read(sessionProvider.future);

    await container.read(sessionProvider.notifier).signIn();

    final state = container.read(sessionProvider);
    expect(state.hasError, isFalse, reason: 'a refused sign-in is not a bug');
    expect(state.value, isA<SignedOut>());
    expect((state.value! as SignedOut).lastFailure, isA<SignInRejected>());
  });

  test('a successful sign-in lands signed in', () async {
    final container = containerWith(
      _FakeSessionRepository(onSignIn: () async => Ok(session())),
    );
    await container.read(sessionProvider.future);

    await container.read(sessionProvider.notifier).signIn();

    expect(container.read(sessionProvider).value, isA<SignedIn>());
    expect(container.read(currentUserProvider), _user);
  });

  test('signing out clears the session and tells the repository', () async {
    final repository = _FakeSessionRepository(
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
      _FakeSessionRepository(
        onRestore: () async => const Err(AuthUnavailable()),
      ),
    );
    await container.read(sessionProvider.future);

    container.read(sessionProvider.notifier).acknowledgeFailure();

    expect((container.read(sessionProvider).value! as SignedOut).lastFailure,
        isNull);
  });

  test('currentUser is null unless somebody is signed in', () async {
    final container = containerWith(_FakeSessionRepository());
    await container.read(sessionProvider.future);

    expect(container.read(currentUserProvider), isNull);
  });
}
