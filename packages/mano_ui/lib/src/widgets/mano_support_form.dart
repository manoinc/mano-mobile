import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_choice_chip.dart';
import 'mano_text_field.dart';

/// A support request: its kind, a subject and a description; the screen sends it.
class ManoSupportForm extends StatelessWidget {
  const ManoSupportForm({
    required this.kinds,
    required this.selectedKind,
    required this.onKind,
    required this.subject,
    required this.description,
    required this.onChanged,
    this.subjectError,
    this.descriptionError,
    this.kindLabel = 'Tipo de solicitud',
    this.subjectLabel = 'Asunto',
    this.descriptionLabel = 'Cuéntanos qué pasó',
    super.key,
  });

  final List<String> kinds;
  final int selectedKind;
  final ValueChanged<int> onKind;
  final TextEditingController subject;
  final TextEditingController description;

  /// Called on every keystroke in either field.
  final VoidCallback onChanged;
  final String? subjectError;
  final String? descriptionError;
  final String kindLabel;
  final String subjectLabel;
  final String descriptionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          kindLabel,
          style: theme.textTheme.labelMedium?.copyWith(color: ManoColors.faint),
        ),
        const SizedBox(height: ManoSpacing.sm),
        Wrap(
          spacing: ManoSpacing.sm,
          runSpacing: ManoSpacing.sm,
          children: [
            for (final (i, kind) in kinds.indexed)
              ManoChoiceChip(
                label: kind,
                selected: i == selectedKind,
                onTap: () => onKind(i),
              ),
          ],
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoTextField(
          key: const Key('support-subject'),
          label: subjectLabel,
          controller: subject,
          errorText: subjectError,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoTextField(
          key: const Key('support-description'),
          label: descriptionLabel,
          controller: description,
          errorText: descriptionError,
          textCapitalization: TextCapitalization.sentences,
          minLines: 4,
          maxLines: 8,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
