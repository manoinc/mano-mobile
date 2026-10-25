import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Step 3: the password; leaving it creates the account.
class PasswordStepScreen extends ConsumerStatefulWidget {
  const PasswordStepScreen({required this.flow, super.key});

  final OnboardingRegistration flow;

  @override
  ConsumerState<PasswordStepScreen> createState() => _PasswordStepScreenState();
}

class _PasswordStepScreenState extends ConsumerState<PasswordStepScreen> {
  late final TextEditingController _password = TextEditingController(
    text: widget.flow.password,
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Not `autofocus`: the outgoing step unfocuses on its way out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _password.dispose();
    _focus.dispose();
    super.dispose();
  }

  OnboardingFlowNotifier get _notifier =>
      ref.read(onboardingFlowProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final flow = widget.flow;
    final busy = flow.status is RegistrationSubmitting;
    final problem = flow.showProblems ? validatePassword(flow.password) : null;

    return ManoStepScaffold(
      onBack: busy ? null : _notifier.back,
      headline: 'Crea una contraseña',
      subhead: 'Al menos 8 caracteres, con letras y números.',
      trailingLabel: 'Ahora no',
      onTrailing: busy ? null : _notifier.skipRegistration,
      primaryLabel: 'Crear cuenta',
      onPrimary: _notifier.createAccount,
      busy: busy,
      children: [
        ManoTextField(
          label: 'Contraseña',
          controller: _password,
          focusNode: _focus,
          obscureText: true,
          enabled: !busy,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          errorText: switch (flow.status) {
            RegistrationAccountRejected(:final failure) => authFailureCopy(
              failure,
            ),
            _ => problem == null ? null : credentialProblemCopy(problem),
          },
          onChanged: _notifier.editPassword,
          onSubmitted: (_) => _notifier.createAccount(),
        ),
      ],
    );
  }
}
