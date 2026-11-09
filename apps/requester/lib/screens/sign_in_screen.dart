import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../features/onboarding/widgets/google_mark.dart';

/// The shared phone sign-in, routed through this app's onboarding flow.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({required this.failure, super.key});

  /// A failure the session carries, e.g. an expired session after restore.
  final AuthFailure? failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(phoneSignInProvider);
    final phone = ref.read(phoneSignInProvider.notifier);
    final flow = ref.read(onboardingFlowProvider.notifier);
    final shown = state.failure ?? failure;
    final codeStep = state.challenge != null;

    // A new account is asked its name first; the flow decides.
    void enter(Session? session) {
      if (session != null) flow.enter(session);
    }

    void openEmail() => _openEmail(context, ref);

    return ManoPhoneSignInScreen(
      countries: [
        for (final c in supportedCountries)
          ManoCountryOption(
            code: c.code,
            flag: c.flag,
            name: c.name,
            dialCode: '+${c.dialCode}',
          ),
      ],
      countryCode: state.country.code,
      onCountrySelected: (code) => phone.selectCountry(countryByCode(code)!),
      phone: state.phone,
      onPhoneChanged: phone.editPhone,
      onSendCode: phone.sendCode,
      onTrouble: openEmail,
      googleMark: const GoogleMark(),
      appleMark: const Icon(Icons.apple, size: 22),
      onGoogle: () async =>
          enter(await phone.signInWith(SocialProvider.google)),
      onApple: () async => enter(await phone.signInWith(SocialProvider.apple)),
      onEmail: openEmail,
      onClose: flow.back,
      codeSentTo: state.challenge?.maskedPhone,
      code: state.code,
      onCodeChanged: phone.editCode,
      onVerify: () async => enter(await phone.verify()),
      canVerify: state.canVerify,
      onResend: phone.resend,
      onChangeNumber: phone.changeNumber,
      busy: state.busy,
      phoneError: state.showPhoneProblem
          ? phoneNumberProblemCopy(state.country)
          : null,
      codeError: codeStep && shown != null ? authFailureCopy(shown) : null,
      notice: codeStep || shown == null
          ? null
          : ManoNotice(
              message: authFailureCopy(shown),
              tone: _toneFor(shown),
              onDismiss: () {
                phone.acknowledgeFailure();
                ref.read(sessionProvider.notifier).acknowledgeFailure();
              },
            ),
    );
  }

  void _openEmail(BuildContext context, WidgetRef ref) {
    // Captured first: a successful sign-in replaces this screen, and its ref with it.
    final session = ref.read(sessionProvider.notifier);
    final flow = ref.read(onboardingFlowProvider.notifier);
    showManoSheet<void>(
      context: context,
      builder: (sheet) => ManoCredentialsSheet(
        title: 'Inicia sesión',
        message: 'Con el correo de tu cuenta Mano.',
        submitLabel: 'Entrar',
        onSubmit: (email, password) async {
          final failure = await session.signIn(
            Credentials(email: email, password: password),
          );
          if (failure != null) {
            session.acknowledgeFailure();
            return authFailureCopy(failure);
          }
          if (sheet.mounted) Navigator.of(sheet).pop();
          return null;
        },
        secondaryLabel: 'Crear cuenta con correo',
        onSecondary: () {
          Navigator.of(sheet).pop();
          flow.startRegistration();
        },
      ),
    );
  }

  /// Backing out is not an error, and must not be dressed as one.
  ManoNoticeTone _toneFor(AuthFailure failure) => switch (failure) {
    SignInCancelled() => ManoNoticeTone.info,
    SessionExpired() ||
    AuthUnavailable() ||
    TooManyAttempts() => ManoNoticeTone.warning,
    SignInRejected() ||
    WrongCredentials() ||
    EmailAlreadyRegistered() ||
    InvalidCode() ||
    CodeExpired() => ManoNoticeTone.error,
  };
}
