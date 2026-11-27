import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Which bank, from billing's list.
class BankStep extends StatelessWidget {
  const BankStep({
    required this.banks,
    required this.selectedCode,
    required this.progress,
    required this.onPick,
    required this.onNext,
    required this.onBack,
    required this.onRetry,
    super.key,
  });

  final AsyncValue<List<Bank>> banks;
  final VoidCallback onRetry;
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
    child: switch (banks) {
      AsyncData(:final value) => _list(context, value),
      AsyncError() => ManoEmptyState(
        icon: Icons.cloud_off_outlined,
        message: 'No pudimos cargar los bancos',
        ctaLabel: 'Reintentar',
        onCta: onRetry,
      ),
      _ => const ManoSkeletonList(),
    },
  );

  Widget _list(BuildContext context, List<Bank> banks) => Column(
    children: [
      for (final bank in banks)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(bank.name),
          selected: bank.code == selectedCode,
          selectedColor: context.palette.ink,
          trailing: bank.code == selectedCode
              ? const Icon(Icons.check_circle, color: ManoColors.flame)
              : Icon(
                  Icons.radio_button_unchecked,
                  color: context.palette.stone,
                ),
          onTap: () => onPick(bank.code),
        ),
    ],
  );
}
