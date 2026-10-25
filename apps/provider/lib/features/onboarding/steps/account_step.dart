import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../sign_in_sheet.dart';

/// The email or the password of the new account; leaving the password creates it.
class AccountStep extends ConsumerStatefulWidget {
  const AccountStep({required this.state, super.key});

  final ProviderOnboardingState state;

  @override
  ConsumerState<AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends ConsumerState<AccountStep> {
  // Seeded once; resetting .text on every build would jump the cursor.
  late final _controller = TextEditingController(text: _seed);
  // Claimed explicitly: autofocus loses to the outgoing step's field mid-transition.
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  ProviderOnboardingState get _s => widget.state;

  bool get _isEmail => _s.step == ProviderOnboardingStep.email;

  String get _seed => _isEmail ? _s.email : _s.password;

  ProviderOnboardingNotifier get _notifier =>
      ref.read(providerOnboardingProvider.notifier);

  void _submit() => _isEmail ? _notifier.next() : _notifier.createAccount();

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final busy = s.status is ProviderOnboardingSubmitting;
    final refusal = switch (s.status) {
      ProviderAccountRejected(:final failure) => failure,
      _ => null,
    };
    final problem = !s.showProblems
        ? null
        : _isEmail
        ? validateEmail(s.email)
        : validatePassword(s.password);

    return ManoQuestionStep(
      title: _isEmail ? '¿Cuál es tu correo?' : 'Crea una contraseña',
      subtitle: _isEmail
          ? 'Con él entras a Mano Profesionales.'
          : 'Al menos 8 caracteres, con letras y números.',
      progress: s.progress,
      primaryLabel: _isEmail ? 'Continuar' : 'Crear cuenta',
      onPrimary: s.stepComplete && !busy ? _submit : null,
      busy: busy,
      onBack: busy ? null : _notifier.back,
      onSkip: busy ? null : _notifier.browseAsGuest,
      skipLabel: 'Ahora no',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ManoTextField(
            label: _isEmail ? 'Correo' : 'Contraseña',
            controller: _controller,
            focusNode: _focus,
            enabled: !busy,
            obscureText: !_isEmail,
            keyboardType: _isEmail ? TextInputType.emailAddress : null,
            textInputAction: TextInputAction.done,
            autofillHints: [
              _isEmail ? AutofillHints.email : AutofillHints.newPassword,
            ],
            errorText: refusal != null
                ? authFailureCopy(refusal)
                : problem == null
                ? null
                : credentialProblemCopy(problem),
            onChanged: _isEmail ? _notifier.editEmail : _notifier.editPassword,
            onSubmitted: (_) => _submit(),
          ),
          if (refusal is EmailAlreadyRegistered)
            ManoTextAction(
              label: 'Iniciar sesión',
              padding: EdgeInsets.zero,
              onPressed: () => showSignInSheet(context, ref),
            ),
        ],
      ),
    );
  }
}
