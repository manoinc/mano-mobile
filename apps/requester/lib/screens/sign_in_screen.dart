import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../features/onboarding/widgets/google_mark.dart';

/// The way in: phone and code first, then Google or Apple, with email as the fallback.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({required this.failure, super.key});

  /// A failure the session carries, e.g. an expired session after restore.
  final AuthFailure? failure;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late final TextEditingController _phone;

  PhoneSignInNotifier get _notifier => ref.read(phoneSignInProvider.notifier);

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

  // Routed by the onboarding flow: a new account is asked its name first.
  void _enter(Session? session) {
    if (session == null) return;
    ref.read(onboardingFlowProvider.notifier).enter(session);
  }

  Future<void> _verify() async => _enter(await _notifier.verify());

  Future<void> _social(SocialProvider provider) async =>
      _enter(await _notifier.signInWith(provider));

  void _openEmail() {
    showManoSheet<void>(
      context: context,
      builder: (sheet) => ManoCredentialsSheet(
        title: 'Inicia sesión',
        message: 'Con el correo de tu cuenta Mano.',
        submitLabel: 'Entrar',
        onSubmit: (email, password) => _signIn(sheet, email, password),
        secondaryLabel: 'Crear cuenta con correo',
        onSecondary: () {
          Navigator.of(sheet).pop();
          ref.read(onboardingFlowProvider.notifier).startRegistration();
        },
      ),
    );
  }

  // Resolves to the copy to show inside the sheet, or closes it on success.
  Future<String?> _signIn(
    BuildContext sheet,
    String email,
    String password,
  ) async {
    // Captured first: a successful sign-in replaces this screen, and its ref with it.
    final session = ref.read(sessionProvider.notifier);
    final failure = await session.signIn(
      Credentials(email: email, password: password),
    );
    if (failure != null) {
      session.acknowledgeFailure();
      return authFailureCopy(failure);
    }
    if (sheet.mounted) Navigator.of(sheet).pop();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(phoneSignInProvider);
    final challenge = state.challenge;
    final failure = state.failure ?? widget.failure;

    final notice = failure == null || challenge != null
        ? null
        : ManoNotice(
            message: authFailureCopy(failure),
            tone: _toneFor(failure),
            onDismiss: () {
              _notifier.acknowledgeFailure();
              ref.read(sessionProvider.notifier).acknowledgeFailure();
            },
          );

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
      onClose: ref.read(onboardingFlowProvider.notifier).back,
      busy: state.busy,
      notice: notice,
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
          onPressed: state.busy ? null : _openEmail,
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

  /// The domain says what went wrong; the screen decides how loudly to say
  /// it. Backing out is not an error, and must not be dressed as one.
  ManoNoticeTone _toneFor(AuthFailure failure) => switch (failure) {
    SignInCancelled() => ManoNoticeTone.info,
    SessionExpired() => ManoNoticeTone.warning,
    AuthUnavailable() => ManoNoticeTone.warning,
    TooManyAttempts() => ManoNoticeTone.warning,
    SignInRejected() ||
    WrongCredentials() ||
    EmailAlreadyRegistered() ||
    InvalidCode() ||
    CodeExpired() => ManoNoticeTone.error,
  };
}
