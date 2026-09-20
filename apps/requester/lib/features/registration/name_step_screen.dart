import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'field_copy.dart';

/// Step 1: who you are.
class NameStepScreen extends ConsumerStatefulWidget {
  const NameStepScreen({required this.flow, super.key});

  final OnboardingRegistration flow;

  @override
  ConsumerState<NameStepScreen> createState() => _NameStepScreenState();
}

class _NameStepScreenState extends ConsumerState<NameStepScreen> {
  late final TextEditingController _given;
  late final TextEditingController _family;
  final FocusNode _givenFocus = FocusNode();
  final FocusNode _familyFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Seeded once. Assigning to .text on every build would drop the cursor to
    // the end mid-word.
    _given = TextEditingController(text: widget.flow.draft.givenName);
    _family = TextEditingController(text: widget.flow.draft.familyName);
    // Not `autofocus`: the outgoing step unfocuses on its way out, and that
    // lands after the incoming field has already asked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _givenFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _given.dispose();
    _family.dispose();
    _givenFocus.dispose();
    _familyFocus.dispose();
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
    final show = widget.flow.showProblems;

    final givenProblem = show ? validateGivenName(draft.givenName) : null;
    final familyProblem = show ? validateFamilyName(draft.familyName) : null;

    return ManoStepScaffold(
      headline: '¿Cómo te llamas?',
      subhead: 'Así te van a reconocer los profesionales.',
      trailingLabel: 'Ahora no',
      onTrailing: _notifier.skipRegistration,
      primaryLabel: 'Siguiente',
      onPrimary: _next,
      children: [
        ManoTextField(
          label: 'Nombre',
          controller: _given,
          focusNode: _givenFocus,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          errorText: givenProblem == null
              ? null
              : nameProblemCopy(givenProblem, field: 'nombre'),
          onChanged: (value) => _notifier.editName(givenName: value),
          onSubmitted: (_) => _familyFocus.requestFocus(),
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoTextField(
          label: 'Apellido',
          controller: _family,
          focusNode: _familyFocus,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          errorText: familyProblem == null
              ? null
              : nameProblemCopy(familyProblem, field: 'apellido'),
          onChanged: (value) => _notifier.editName(familyName: value),
          onSubmitted: (_) => _next(),
        ),
      ],
    );
  }
}
