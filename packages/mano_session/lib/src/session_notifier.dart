import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import 'session_providers.dart';
import 'session_state.dart';

/// Holds whether anyone is signed in, runs the transitions, and renews the token on demand.
///
/// Modelled failures land in [AsyncData] as a [SignedOut] carrying the reason;
/// only a bug becomes [AsyncError]. No transition publishes a bare
/// [AsyncLoading], because the apps' roots switch on `state.value`.
final class SessionManager extends AsyncNotifier<SessionState> {
  /// How long before expiry a token is renewed instead of handed out.
  static const renewalMargin = Duration(minutes: 1);

  SessionRepository get _repository => ref.read(sessionRepositoryProvider);

  // One renewal at a time; concurrent callers share it.
  Future<String?>? _renewing;

  @override
  Future<SessionState> build() async {
    return switch (await _repository.restore()) {
      Ok(value: final session?) => SignedIn(session),
      Ok() => const SignedOut(),
      Err(:final failure) => SignedOut(lastFailure: failure),
    };
  }

  /// Resolves to the failure, or `null` once signed in.
  Future<AuthFailure?> signIn(Credentials credentials) =>
      _authenticate(() => _repository.signIn(credentials));

  /// Resolves to the failure, or `null` once the new account is signed in.
  ///
  /// The account takes this app's role: Solicitante or Proveedor.
  Future<AuthFailure?> signUp(Credentials credentials) {
    final role = ref.read(manoConfigProvider).appRole;
    return _authenticate(() => _repository.signUp(credentials, role: role));
  }

  /// Takes a session started by phone or social sign-in.
  void adopt(Session session) => state = AsyncData(SignedIn(session));

  /// Lets somebody without an account into the app; never demotes a signed-in user.
  void browseAsGuest() {
    if (state.value is! SignedIn) state = const AsyncData(Guest());
  }

  /// Takes a guest back to the door to sign in or register.
  void leaveGuest() {
    if (state.value is Guest) state = const AsyncData(SignedOut());
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncData(SignedOut());
  }

  /// Clears a failure the user has already been shown.
  void acknowledgeFailure() {
    if (state.value case SignedOut(lastFailure: != null)) {
      state = const AsyncData(SignedOut());
    }
  }

  /// A token worth sending now, renewed first when it is about to expire; `null` runs anonymously.
  Future<String?> freshAccessToken() async {
    if (state.value case SignedIn(:final session)) {
      if (!session.expiresWithin(renewalMargin)) return session.accessToken;
      return _renewing ??= _renew(session).whenComplete(() => _renewing = null);
    }
    return null;
  }

  Future<String?> _renew(Session expiring) async {
    final result = await _repository.refresh();
    if (state.value is! SignedIn) return null;
    switch (result) {
      case Ok(:final value):
        state = AsyncData(SignedIn(value));
        return value.accessToken;
      case Err(failure: AuthUnavailable()) when !expiring.isExpired():
        return expiring.accessToken;
      case Err(:final failure):
        state = AsyncData(SignedOut(lastFailure: failure));
        return null;
    }
  }

  Future<AuthFailure?> _authenticate(
    Future<Result<Session, AuthFailure>> Function() attempt,
  ) async {
    state = await AsyncValue.guard<SessionState>(() async {
      return switch (await attempt()) {
        Ok(:final value) => SignedIn(value),
        Err(:final failure) => SignedOut(lastFailure: failure),
      };
    });
    return switch (state.value) {
      SignedOut(:final lastFailure) => lastFailure,
      _ => null,
    };
  }
}

/// The app's session.
final sessionProvider = AsyncNotifierProvider<SessionManager, SessionState>(
  SessionManager.new,
);

/// The signed-in user, or `null` for guests and the signed out.
final currentUserProvider = Provider<AuthenticatedUser?>((ref) {
  return switch (ref.watch(sessionProvider).value) {
    SignedIn(:final user) => user,
    _ => null,
  };
});

/// The bearer token gateway calls carry, or `null` to run anonymously.
final accessTokenProvider = Provider<String?>((ref) {
  return switch (ref.watch(sessionProvider).value) {
    SignedIn(:final session) => session.accessToken,
    _ => null,
  };
});

/// Whether there is an account behind this session; guests are told to make one.
final hasAccountProvider = Provider<bool>(
  (ref) => ref.watch(sessionProvider).value is SignedIn,
);
