import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../onboarding_copy.dart';

/// One question of the sign-up, picked by [ProviderOnboardingState.step].
class QuestionStep extends ConsumerStatefulWidget {
  const QuestionStep({required this.state, super.key});

  final ProviderOnboardingState state;

  @override
  ConsumerState<QuestionStep> createState() => _QuestionStepState();
}

class _QuestionStepState extends ConsumerState<QuestionStep> {
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

  ProviderOnboardingState get _s => widget.state;

  ProviderOnboardingNotifier get _notifier =>
      ref.read(providerOnboardingProvider.notifier);

  String get _seed => switch (_s.step) {
    ProviderOnboardingStep.name => _s.displayName,
    ProviderOnboardingStep.phone => _s.phone,
    ProviderOnboardingStep.zone => _s.workZone,
    ProviderOnboardingStep.experience => _s.experience,
    ProviderOnboardingStep.bio => _s.bio,
    _ => '',
  };

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  // The keyboard stays up between questions, as in Nubank.
  void _next() => _notifier.next();

  String? _problem(ProfileProblem? Function(String) validate, String copy) {
    if (!_s.showProblems) return null;
    return validate(_controller.text) == null ? null : copy;
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;

    return ManoQuestionStep(
      title: _title(s.step),
      subtitle: _subtitle(s.step),
      progress: s.progress,
      primaryLabel: 'Continuar',
      onPrimary: s.stepComplete ? _next : null,
      onBack: _notifier.back,
      onSkip: s.step == ProviderOnboardingStep.bio ? _notifier.skip : null,
      child: switch (s.step) {
        ProviderOnboardingStep.name => ManoTextField(
          label: 'Nombre completo',
          controller: _controller,
          focusNode: _focus,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          errorText: _problem(
            validateDisplayName,
            displayNameProblemCopy(
              validateDisplayName(_controller.text) ?? ProfileProblem.empty,
            ),
          ),
          onChanged: _notifier.editDisplayName,
          onSubmitted: (_) => _next(),
        ),
        ProviderOnboardingStep.phone => ManoTextField(
          label: 'Celular',
          controller: _controller,
          focusNode: _focus,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          errorText: _problem(
            validatePhone,
            phoneProblemCopy(
              validatePhone(_controller.text) ?? ProfileProblem.empty,
            ),
          ),
          onChanged: _notifier.editPhone,
          onSubmitted: (_) => _next(),
        ),
        ProviderOnboardingStep.zone => ManoTextField(
          label: 'Zona de cobertura',
          controller: _controller,
          focusNode: _focus,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          errorText: _problem(
            validateWorkZone,
            workZoneProblemCopy(ProfileProblem.empty),
          ),
          onChanged: _notifier.editWorkZone,
          onSubmitted: (_) => _next(),
        ),
        ProviderOnboardingStep.services => _ServiceChoices(
          selected: s.categories,
          onToggle: _notifier.toggleCategory,
        ),
        ProviderOnboardingStep.experience => ManoTextField(
          label: 'Años de experiencia',
          controller: _controller,
          focusNode: _focus,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          errorText: _problem(validateExperience, experienceProblemCopy),
          onChanged: _notifier.editExperience,
          onSubmitted: (_) => _next(),
        ),
        _ => ManoTextField(
          label: 'Descripción',
          controller: _controller,
          focusNode: _focus,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          // Live, because the action is already open for an empty bio.
          errorText: validateBio(s.bio) == null ? null : bioProblemCopy,
          onChanged: _notifier.editBio,
        ),
      },
    );
  }
}

String _title(ProviderOnboardingStep step) => switch (step) {
  ProviderOnboardingStep.name => '¿Cuál es tu nombre?',
  ProviderOnboardingStep.phone => '¿Cuál es tu celular?',
  ProviderOnboardingStep.zone => '¿En qué zona trabajas?',
  ProviderOnboardingStep.services => '¿Qué servicios ofreces?',
  ProviderOnboardingStep.experience => '¿Cuántos años de experiencia tienes?',
  _ => 'Cuéntales algo sobre ti',
};

String? _subtitle(ProviderOnboardingStep step) => switch (step) {
  ProviderOnboardingStep.name => 'Así te verán los clientes.',
  ProviderOnboardingStep.phone => 'Te avisaremos cuando tengas una solicitud.',
  ProviderOnboardingStep.zone => 'Por ejemplo, Chapinero.',
  ProviderOnboardingStep.services => 'Elige uno o más.',
  ProviderOnboardingStep.experience => 'Si apenas empiezas, escribe 0.',
  _ => 'Opcional. Una o dos frases bastan.',
};

class _ServiceChoices extends StatelessWidget {
  const _ServiceChoices({required this.selected, required this.onToggle});

  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: ManoSpacing.sm,
    runSpacing: ManoSpacing.sm,
    children: [
      for (final category in ServiceCategories.all)
        _ServiceChip(
          label: category.label,
          selected: selected.contains(category.id),
          onTap: () => onToggle(category.id),
        ),
    ],
  );
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? ManoColors.flame.withValues(alpha: 0.12)
            : ManoColors.stone,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? ManoColors.flame : Colors.transparent,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ManoSpacing.md,
              vertical: ManoSpacing.sm + ManoSpacing.xs,
            ),
            child: Text(
              label,
              style: text.titleSmall?.copyWith(
                color: selected ? ManoColors.flame : ManoColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
