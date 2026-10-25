import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

const _detailProblems = {
  ProjectDraftProblem.emptyTitle,
  ProjectDraftProblem.emptyDescription,
  ProjectDraftProblem.titleTooLong,
  ProjectDraftProblem.descriptionTooLong,
};

/// Step 2: a title and a description of the work.
class DetailsStep extends StatelessWidget {
  const DetailsStep({
    required this.draft,
    required this.progress,
    required this.title,
    required this.description,
    required this.onChanged,
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final ProjectDraft draft;
  final double progress;
  final TextEditingController title;
  final TextEditingController description;
  final VoidCallback onChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final problems = draft.problems;
    return ManoQuestionStep(
      title: 'Cuéntanos el trabajo',
      progress: progress,
      primaryLabel: 'Continuar',
      onPrimary: problems.any(_detailProblems.contains) ? null : onNext,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ManoTextField(
            key: const Key('project-title'),
            label: 'Título',
            controller: title,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
            errorText: problems.contains(ProjectDraftProblem.titleTooLong)
                ? 'Máximo 120 caracteres.'
                : null,
          ),
          const SizedBox(height: ManoSpacing.lg),
          ManoTextField(
            key: const Key('project-description'),
            label: 'Descripción',
            controller: description,
            textCapitalization: TextCapitalization.sentences,
            minLines: 4,
            maxLines: 8,
            onChanged: (_) => onChanged(),
            helperText: 'Entre más detalles, mejores cotizaciones.',
            errorText: problems.contains(ProjectDraftProblem.descriptionTooLong)
                ? 'Es demasiado larga.'
                : null,
          ),
        ],
      ),
    );
  }
}
