import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../session_providers.dart';

/// Where a phone sign-in stands: a number being typed, or a code once one is sent.
final class PhoneSignInState {
  const PhoneSignInState({
    this.phone = '',
    this.code = '',
    this.challenge,
    this.busy = false,
    this.showPhoneProblem = false,
    this.failure,
  });

  /// As typed, e.g. `300 123 4567`.
  final String phone;
  final String code;

  /// Set once a code is on its way; the screen then asks for the code.
  final OtpChallenge? challenge;
  final bool busy;

  /// The number is shown as wrong after the first refused Continuar, not on every keystroke.
  final bool showPhoneProblem;
  final AuthFailure? failure;

  String? get e164 => colombianE164(phone);

  bool get canSend => !busy && e164 != null;

  bool get canVerify => !busy && challenge != null && isWellFormedOtp(code);

  PhoneSignInState copyWith({
    String? phone,
    String? code,
    OtpChallenge? Function()? challenge,
    bool? busy,
    bool? showPhoneProblem,
    AuthFailure? Function()? failure,
  }) => PhoneSignInState(
    phone: phone ?? this.phone,
    code: code ?? this.code,
    challenge: challenge == null ? this.challenge : challenge(),
    busy: busy ?? this.busy,
    showPhoneProblem: showPhoneProblem ?? this.showPhoneProblem,
    failure: failure == null ? this.failure : failure(),
  );
}

/// Phone + code (and Google / Apple beside it), shared by both apps; it hands back the session and leaves routing to the app.
final class PhoneSignInNotifier extends Notifier<PhoneSignInState> {
  PasswordlessAuth get _auth => ref.read(passwordlessAuthProvider);

  @override
  PhoneSignInState build() => const PhoneSignInState();

  void editPhone(String value) => state = state.copyWith(
    phone: value,
    showPhoneProblem: false,
    failure: () => null,
  );

  void editCode(String value) =>
      state = state.copyWith(code: value, failure: () => null);

  Future<void> sendCode() async {
    if (state.busy) return;
    final phone = state.e164;
    if (phone == null) {
      state = state.copyWith(showPhoneProblem: true);
      return;
    }
    state = state.copyWith(busy: true, failure: () => null);
    final role = ref.read(manoConfigProvider).appRole;
    final result = await _auth.sendCode(phone, role: role);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        busy: false,
        code: '',
        challenge: () => value,
      ),
      Err(:final failure) => state.copyWith(
        busy: false,
        failure: () => failure,
      ),
    };
  }

  Future<void> resend() async {
    final challenge = state.challenge;
    if (challenge == null || state.busy) return;
    state = state.copyWith(busy: true, code: '', failure: () => null);
    final result = await _auth.resend(challenge);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(busy: false, challenge: () => value),
      Err(:final failure) => state.copyWith(
        busy: false,
        failure: () => failure,
      ),
    };
  }

  /// The session once the code is right; `null` with [PhoneSignInState.failure] set otherwise.
  Future<Session?> verify() async {
    final challenge = state.challenge;
    if (!state.canVerify || challenge == null) return null;
    state = state.copyWith(busy: true, failure: () => null);
    final result = await _auth.verify(challenge, state.code);
    if (!ref.mounted) return null;
    switch (result) {
      case Ok(:final value):
        state = state.copyWith(busy: false);
        return value;
      case Err(:final failure):
        state = state.copyWith(busy: false, code: '', failure: () => failure);
        return null;
    }
  }

  /// Google or Apple from the same screen; closing their sheet leaves no failure behind.
  Future<Session?> signInWith(SocialProvider provider) async {
    if (state.busy) return null;
    state = state.copyWith(busy: true, failure: () => null);
    final role = ref.read(manoConfigProvider).appRole;
    final result = await ref
        .read(socialAuthProvider)
        .signIn(provider, role: role);
    if (!ref.mounted) return null;
    switch (result) {
      case Ok(:final value):
        state = state.copyWith(busy: false);
        return value;
      case Err(failure: SignInCancelled()):
        state = state.copyWith(busy: false);
        return null;
      case Err(:final failure):
        state = state.copyWith(busy: false, failure: () => failure);
        return null;
    }
  }

  /// Clears a failure the person has already seen.
  void acknowledgeFailure() => state = state.copyWith(failure: () => null);

  /// Back to the number, keeping what was typed.
  void changeNumber() => state = state.copyWith(
    code: '',
    challenge: () => null,
    failure: () => null,
  );
}

/// Auto-disposed, so the next visit to the sign-in screen starts from an empty number.
final phoneSignInProvider =
    NotifierProvider.autoDispose<PhoneSignInNotifier, PhoneSignInState>(
      PhoneSignInNotifier.new,
    );
