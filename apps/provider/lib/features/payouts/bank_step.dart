import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Which bank, from the static list.
class BankStep extends StatelessWidget {
  const BankStep({
    required this.selectedCode,
    required this.progress,
    required this.onPick,
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final String selectedCode;
  final double progress;
  final ValueChanged<String> onPick;
  final VoidCallback? onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => ManoQuestionStep(
    title: '¿En qué banco?',
    progress: progress,
    primaryLabel: 'Continuar',
    onPrimary: onNext,
    onBack: onBack,
    child: Column(
      children: [
        for (final bank in ColombianBanks.all)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(bank.name),
            selected: bank.code == selectedCode,
            selectedColor: ManoColors.ink,
            trailing: bank.code == selectedCode
                ? const Icon(Icons.check_circle, color: ManoColors.flame)
                : const Icon(
                    Icons.radio_button_unchecked,
                    color: ManoColors.stone,
                  ),
            onTap: () => onPick(bank.code),
          ),
      ],
    ),
  );
}
