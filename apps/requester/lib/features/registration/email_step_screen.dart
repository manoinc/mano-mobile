import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Step 2: the email the account signs in with.
class EmailStepScreen extends ConsumerStatefulWidget {
  const EmailStepScreen({required this.flow, super.key});

  final OnboardingRegistration flow;

  @override
  ConsumerState<EmailStepScreen> createState() => _EmailStepScreenState();
}

class _EmailStepScreenState extends ConsumerState<EmailStepScreen> {
  late final TextEditingController _email = TextEditingController(
    text: widget.flow.email,
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
    _email.dispose();
    _focus.dispose();
    super.dispose();
  }

  OnboardingFlowNotifier get _notifier =>
      ref.read(onboardingFlowProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final flow = widget.flow;
    final refusal = switch (flow.status) {
      RegistrationAccountRejected(:final failure) => failure,
      _ => null,
    };
    final problem = flow.showProblems ? validateEmail(flow.email) : null;

    return ManoStepScaffold(
      onBack: _notifier.back,
      headline: '¿Cuál es tu correo?',
      subhead: 'Con él entras a tu cuenta Mano.',
      trailingLabel: 'Ahora no',
      onTrailing: _notifier.skipRegistration,
      primaryLabel: 'Siguiente',
      onPrimary: _notifier.next,
      children: [
        ManoTextField(
          label: 'Correo',
          controller: _email,
          focusNode: _focus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          errorText: refusal != null
              ? authFailureCopy(refusal)
              : problem == null
              ? null
              : credentialProblemCopy(problem),
          onChanged: _notifier.editEmail,
          onSubmitted: (_) => _notifier.next(),
        ),
        if (refusal is EmailAlreadyRegistered)
          Align(
            alignment: Alignment.centerLeft,
            child: ManoTextAction(
              label: 'Iniciar sesión',
              padding: EdgeInsets.zero,
              onPressed: _notifier.startSignIn,
            ),
          ),
      ],
    );
  }
}
