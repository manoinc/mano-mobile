import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Step 4: an optional budget on a keypad.
class BudgetStep extends StatelessWidget {
  const BudgetStep({
    required this.draft,
    required this.progress,
    required this.onBudget,
    required this.onNext,
    required this.onSkip,
    required this.onBack,
    super.key,
  });

  final ProjectDraft draft;
  final double progress;
  final ValueChanged<int?> onBudget;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final budget = draft.budgetCop;
    return ManoQuestionStep(
      title: '¿Cuánto piensas invertir?',
      subtitle: 'Opcional. Los profesionales cotizan igual.',
      progress: progress,
      primaryLabel: 'Continuar',
      onPrimary: draft.problems.contains(ProjectDraftProblem.negativeBudget)
          ? null
          : onNext,
      onBack: onBack,
      onSkip: onSkip,
      child: ManoAmountPad(
        amountLabel: ManoFormat.cop(budget ?? 0),
        helperText: 'Puedes negociarlo después.',
        onDigit: (digits) => onBudget(typeAmount(budget, digits)),
        onBackspace: () => onBudget(eraseAmount(budget)),
      ),
    );
  }
}
