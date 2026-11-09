import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'bank_picker_sheet.dart';
import 'checkout_labels.dart';

/// What PSE asks of the payer: the bank, who pays, and their document.
class CheckoutPseFields extends StatelessWidget {
  const CheckoutPseFields({
    required this.draft,
    required this.banks,
    required this.legalId,
    required this.onChanged,
    super.key,
  });

  final JobPaymentDraft draft;
  final List<Bank> banks;
  final TextEditingController legalId;
  final ValueChanged<JobPaymentDraft Function(JobPaymentDraft)> onChanged;

  @override
  Widget build(BuildContext context) {
    final caption = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: ManoColors.faint);
    final bank = banks.where((b) => b.code == draft.bankCode).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ManoOptionRow(
          icon: Icons.account_balance_outlined,
          label: bank?.name ?? 'Elige tu banco',
          detail: bank == null ? 'El banco desde el que pagas' : 'Banco',
          onPressed: banks.isEmpty
              ? null
              : () async {
                  final code = await showBankPicker(
                    context,
                    banks: banks,
                    selectedCode: draft.bankCode,
                  );
                  if (code == null) return;
                  onChanged((d) => d.copyWith(bankCode: code));
                },
        ),
        const SizedBox(height: ManoSpacing.sm),
        Wrap(
          spacing: ManoSpacing.sm,
          children: [
            for (final type in PsePersonType.values)
              ManoChoiceChip(
                label: personTypeLabel(type),
                selected: draft.personType == type,
                onTap: () => onChanged((d) => d.copyWith(personType: type)),
              ),
          ],
        ),
        const SizedBox(height: ManoSpacing.md),
        Text('Tipo de documento', style: caption),
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
        const SizedBox(height: ManoSpacing.md),
        ManoTextField(
          label: 'Número de documento',
          controller: legalId,
          keyboardType: draft.legalIdType == LegalIdType.pp
              ? TextInputType.text
              : TextInputType.number,
          errorText: checkoutLegalIdError(draft),
          onChanged: (v) => onChanged((d) => d.copyWith(legalId: v)),
        ),
      ],
    );
  }
}
