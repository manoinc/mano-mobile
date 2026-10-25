import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../project_labels.dart';

/// Step 4: everything at a glance, each part editable, then publish.
class ReviewStep extends StatelessWidget {
  const ReviewStep({
    required this.draft,
    required this.busy,
    required this.onEdit,
    required this.onPublish,
    required this.onBack,
    super.key,
  });

  final ProjectDraft draft;
  final bool busy;

  /// Called with the step to go back to.
  final ValueChanged<int> onEdit;
  final VoidCallback onPublish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ManoQuestionStep(
      title: 'Revisa y publica',
      progress: 1,
      primaryLabel: 'Publicar proyecto',
      busy: busy,
      onPrimary: draft.isValid ? onPublish : null,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Part(
            onEdit: () => onEdit(0),
            child: Text(
              ServiceCategories.labelOf(draft.category),
              style: textTheme.labelLarge?.copyWith(color: ManoColors.clay),
            ),
          ),
          _Part(
            onEdit: () => onEdit(1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(draft.title.trim(), style: textTheme.titleMedium),
                const SizedBox(height: ManoSpacing.xs),
                Text(
                  draft.description.trim(),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: ManoColors.muted,
                  ),
                ),
              ],
            ),
          ),
          _Part(
            onEdit: () => onEdit(2),
            child: Text(
              'Presupuesto  ${budgetLabel(draft.budgetCop)}',
              style: textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: ManoSpacing.md),
          Text(
            'Gratis. Te avisamos cuando lleguen cotizaciones.',
            style: textTheme.bodySmall?.copyWith(color: ManoColors.faint),
          ),
        ],
      ),
    );
  }
}

class _Part extends StatelessWidget {
  const _Part({required this.child, required this.onEdit});

  final Widget child;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ManoColors.stone)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ManoSpacing.sm),
        child: Row(
          children: [
            Expanded(child: child),
            ManoTextAction(label: 'Editar', onPressed: onEdit),
          ],
        ),
      ),
    );
  }
}
