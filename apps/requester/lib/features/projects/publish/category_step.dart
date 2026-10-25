import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../explore/category_icons.dart';

/// Step 1: what kind of work.
class CategoryStep extends StatelessWidget {
  const CategoryStep({
    required this.draft,
    required this.progress,
    required this.onPick,
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final ProjectDraft draft;
  final double progress;
  final ValueChanged<String> onPick;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ready = !draft.problems.contains(ProjectDraftProblem.unknownCategory);
    return ManoQuestionStep(
      title: '¿Qué necesitas?',
      progress: progress,
      primaryLabel: 'Continuar',
      onPrimary: ready ? onNext : null,
      onBack: onBack,
      child: Wrap(
        spacing: ManoSpacing.sm,
        runSpacing: ManoSpacing.sm,
        children: [
          for (final category in ServiceCategories.all)
            ManoCategoryChip(
              icon: categoryIcon(category.iconKey),
              label: category.label,
              selected: draft.category == category.id,
              onTap: () => onPick(category.id),
            ),
        ],
      ),
    );
  }
}
