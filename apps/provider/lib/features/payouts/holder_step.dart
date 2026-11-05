import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'payout_labels.dart';

/// Who owns the account: name, document type and number; then save.
class HolderStep extends StatelessWidget {
  const HolderStep({
    required this.draft,
    required this.progress,
    required this.name,
    required this.email,
    required this.legalId,
    required this.busy,
    required this.onChanged,
    required this.onSave,
    required this.onBack,
    super.key,
  });

  final PayoutAccountDraft draft;
  final double progress;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController legalId;
  final bool busy;
  final ValueChanged<PayoutAccountDraft Function(PayoutAccountDraft)> onChanged;
  final VoidCallback? onSave;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => ManoQuestionStep(
    title: '¿A nombre de quién está?',
    subtitle: 'Debe ser tu nombre y tu documento.',
    progress: progress,
    primaryLabel: 'Guardar cuenta',
    onPrimary: onSave,
    busy: busy,
    onBack: onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ManoTextField(
          label: 'Nombre del titular',
          controller: name,
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => onChanged((d) => d.copyWith(holderName: v)),
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoTextField(
          label: 'Correo del titular',
          controller: email,
          keyboardType: TextInputType.emailAddress,
          errorText: holderEmailError(draft),
          onChanged: (v) => onChanged((d) => d.copyWith(holderEmail: v)),
        ),
        const SizedBox(height: ManoSpacing.lg),
        Text(
          'Tipo de documento',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: ManoColors.faint),
        ),
        const SizedBox(height: ManoSpacing.sm),
        Wrap(
          spacing: ManoSpacing.sm,
          runSpacing: ManoSpacing.sm,
          children: [
            for (final type in LegalIdType.values)
              ManoChoiceChip(
                label: legalIdTypeLabel(type),
                selected: draft.legalIdType == type,
                onTap: () => onChanged((d) => d.copyWith(legalIdType: type)),
              ),
          ],
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoTextField(
          label: 'Número de documento',
          controller: legalId,
          keyboardType: draft.legalIdType == LegalIdType.pp
              ? TextInputType.text
              : TextInputType.number,
          errorText: legalIdError(draft),
          onChanged: (v) => onChanged((d) => d.copyWith(legalId: v)),
        ),
      ],
    ),
  );
}
