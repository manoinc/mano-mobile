import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../onboarding_copy.dart';
import '../sign_in_sheet.dart';
import '../widgets/google_mark.dart';

/// The way in: phone and code first, then Google or Apple, with email as the fallback.
class SignInStep extends ConsumerStatefulWidget {
  const SignInStep({super.key});

  @override
  ConsumerState<SignInStep> createState() => _SignInStepState();
}

class _SignInStepState extends ConsumerState<SignInStep> {
  late final TextEditingController _phone;

  PhoneSignInNotifier get _notifier => ref.read(phoneSignInProvider.notifier);

  ProviderOnboardingNotifier get _onboarding =>
      ref.read(providerOnboardingProvider.notifier);

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: ref.read(phoneSignInProvider).phone);
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  // A new account continues the onboarding at the name; a returning one enters the shell.
  void _enter(Session? session, {String? phone}) {
    if (session != null) _onboarding.enter(session, phone: phone);
  }

  Future<void> _verify() async {
    final phone = ref.read(phoneSignInProvider).e164;
    _enter(await _notifier.verify(), phone: phone);
  }

  Future<void> _social(SocialProvider provider) async =>
      _enter(await _notifier.signInWith(provider));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(phoneSignInProvider);
    final challenge = state.challenge;
    final failure = state.failure;

    if (challenge != null) {
      return ManoSignInLayout(
        key: const ValueKey('code'),
        title: 'Confirma tu número',
        message: 'Escribe el código que enviamos a ${challenge.maskedPhone}.',
        onClose: _notifier.changeNumber,
        busy: state.busy,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ManoOtpField(
              value: state.code,
              autofocus: true,
              enabled: !state.busy,
              errorText: failure == null ? null : authFailureCopy(failure),
              onChanged: _notifier.editCode,
              onCompleted: (_) => _verify(),
            ),
            const SizedBox(height: ManoSpacing.md),
            ManoResendTimer(onResend: _notifier.resend, enabled: !state.busy),
          ],
        ),
        primaryLabel: 'Continuar',
        onPrimary: state.canVerify ? _verify : null,
      );
    }

    return ManoSignInLayout(
      key: const ValueKey('phone'),
      title: 'Inicia sesión o regístrate',
      onClose: _onboarding.back,
      busy: state.busy,
      notice: failure == null
          ? null
          : ManoNotice(
              message: authFailureCopy(failure),
              tone: authFailureTone(failure),
              onDismiss: _notifier.acknowledgeFailure,
            ),
      body: ManoPhoneField(
        controller: _phone,
        enabled: !state.busy,
        helperText: 'Te enviaremos un código por SMS.',
        errorText: state.showPhoneProblem ? phoneNumberProblemCopy : null,
        onChanged: _notifier.editPhone,
        onSubmitted: (_) => _notifier.sendCode(),
      ),
      primaryLabel: 'Continuar',
      onPrimary: state.busy ? null : _notifier.sendCode,
      alternatives: [
        ManoOutlineButton(
          label: 'Continuar con correo',
          onPressed: state.busy
              ? null
              : () => showSignInSheet(
                  context,
                  ref,
                  onCreateAccount: _onboarding.start,
                ),
        ),
        ManoPlatformSignInButton(
          googleMark: const GoogleMark(),
          appleMark: const Icon(Icons.apple, size: 22),
          onGoogle: state.busy ? null : () => _social(SocialProvider.google),
          onApple: state.busy ? null : () => _social(SocialProvider.apple),
        ),
      ],
    );
  }
}
