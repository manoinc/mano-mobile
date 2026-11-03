import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'payout_labels.dart';

/// The Nequi phone, or the bank account's type and number.
class DestinationStep extends StatelessWidget {
  const DestinationStep({
    required this.draft,
    required this.progress,
    required this.phone,
    required this.accountNumber,
    required this.onChanged,
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final PayoutAccountDraft draft;
  final double progress;
  final TextEditingController phone;
  final TextEditingController accountNumber;
  final ValueChanged<PayoutAccountDraft Function(PayoutAccountDraft)> onChanged;
  final VoidCallback? onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final nequi = draft.method == PayoutMethod.nequi;
    return ManoQuestionStep(
      title: nequi ? '¿Cuál es tu Nequi?' : 'Tu cuenta',
      subtitle: nequi ? 'El celular con el que entras a Nequi.' : null,
      progress: progress,
      primaryLabel: 'Continuar',
      onPrimary: onNext,
      onBack: onBack,
      child: nequi ? _phone() : _account(context),
    );
  }

  Widget _phone() => ManoTextField(
    label: 'Celular registrado en Nequi',
    controller: phone,
    keyboardType: TextInputType.phone,
    autofocus: true,
    errorText: phoneError(draft),
    onChanged: (v) => onChanged((d) => d.copyWith(phone: v)),
  );

  Widget _account(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Tipo de cuenta',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: ManoColors.faint),
      ),
      const SizedBox(height: ManoSpacing.sm),
      Wrap(
        spacing: ManoSpacing.sm,
        children: [
          for (final type in BankAccountType.values)
            ManoChoiceChip(
              label: accountTypeLabel(type),
              selected: draft.accountType == type,
              onTap: () => onChanged((d) => d.copyWith(accountType: type)),
            ),
        ],
      ),
      const SizedBox(height: ManoSpacing.lg),
      ManoTextField(
        label: 'Número de cuenta',
        controller: accountNumber,
        keyboardType: TextInputType.number,
        errorText: accountNumberError(draft),
        onChanged: (v) => onChanged((d) => d.copyWith(accountNumber: v)),
      ),
    ],
  );
}
