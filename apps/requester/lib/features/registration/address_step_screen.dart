import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'field_copy.dart';

/// Step 2: where you are.
class AddressStepScreen extends ConsumerStatefulWidget {
  const AddressStepScreen({required this.flow, super.key});

  final OnboardingRegistration flow;

  @override
  ConsumerState<AddressStepScreen> createState() => _AddressStepScreenState();
}

class _AddressStepScreenState extends ConsumerState<AddressStepScreen> {
  late final TextEditingController _address = TextEditingController(
    text: widget.flow.draft.address,
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Not `autofocus`: the previous step unfocuses on its way out, and that
    // lands after the incoming field has already asked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _focus.dispose();
    super.dispose();
  }

  OnboardingFlowNotifier get _notifier =>
      ref.read(onboardingFlowProvider.notifier);

  void _next() {
    FocusScope.of(context).unfocus();
    _notifier.next();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.flow.draft;
    final problem = widget.flow.showProblems
        ? validateAddress(draft.address)
        : null;

    return ManoStepScaffold(
      onBack: _notifier.back,
      headline: '¡Un gusto conocerte, ${draft.greetingName}! ¿Dónde vives?',
      subhead: 'La usamos para mostrarte profesionales cerca de ti.',
      trailingLabel: 'Ahora no',
      onTrailing: _notifier.skipRegistration,
      primaryLabel: 'Siguiente',
      onPrimary: _next,
      children: [
        ManoTextField(
          label: 'Dirección',
          controller: _address,
          focusNode: _focus,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          helperText: 'Calle, número y barrio',
          errorText: problem == null ? null : addressProblemCopy(problem),
          onChanged: _notifier.editAddress,
          onSubmitted: (_) => _next(),
        ),
      ],
    );
  }
}
