import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import 'session_providers.dart';
import 'session_state.dart';

/// Holds whether anyone is signed in, and runs the transitions between.
///
/// It orchestrates; it does not decide. Every judgement — whether a grant is
/// recoverable, whether a stored token is worth keeping, what counts as a
/// cancellation — was made below, in the domain and its adapters. This class
/// only converts a [Result] into state a widget can render, which is why it
/// stays this short and why nothing here needs a rule of its own.
final class SessionNotifier extends AsyncNotifier<SessionState> {
  SessionRepository get _repository => ref.read(sessionRepositoryProvider);

  @override
  Future<SessionState> build() => _restore();

  Future<SessionState> _restore() async {
    final result = await _repository.restore();
    return switch (result) {
      // Ok(null) is nobody signed in: an ordinary first launch, and not
      // something to report as a failure.
      Ok(:final value) => value == null ? const SignedOut() : SignedIn(value),
      Err(:final failure) => SignedOut(lastFailure: failure),
    };
  }

  /// Starts an interactive sign-in.
  ///
  /// `AsyncValue.guard` is exactly right here given how failure is split: the
  /// repository returns modelled failures as data, so they land in
  /// [AsyncData] as a [SignedOut] carrying the reason. Only a genuine bug can
  /// throw, and only that becomes [AsyncError]. The two never get confused.
  Future<void> signIn() async {
    state = const AsyncLoading<SessionState>();
    state = await AsyncValue.guard(() async {
      final result = await _repository.signIn();
      return switch (result) {
        Ok(:final value) => SignedIn(value),
        Err(:final failure) => SignedOut(lastFailure: failure),
      };
    });
  }

  /// Ends the session.
  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncData(SignedOut());
  }

  /// Clears a failure the user has already been shown, so it is not repeated
  /// on the next rebuild.
  void acknowledgeFailure() {
    if (state.value case SignedOut(lastFailure: != null)) {
      state = const AsyncData(SignedOut());
    }
  }
}

/// The app's session.
final sessionProvider = AsyncNotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);

/// The signed-in user, or `null`. Convenience for widgets that only need to
/// know who is here.
final currentUserProvider = Provider<AuthenticatedUser?>((ref) {
  final session = ref.watch(sessionProvider).value;
  return switch (session) {
    SignedIn(:final user) => user,
    SignedOut() || null => null,
  };
});
