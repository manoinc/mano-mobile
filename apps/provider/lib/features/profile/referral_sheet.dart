import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'profile_labels.dart';
import 'provider_profile_screen.dart';

Future<void> showReferralSheet(BuildContext context, ReferralProgram program) =>
    showManoSheet<void>(
      context: context,
      builder: (_) => _ReferralSheet(program: program),
    );

class _ReferralSheet extends StatefulWidget {
  const _ReferralSheet({required this.program});

  final ReferralProgram program;

  @override
  State<_ReferralSheet> createState() => _ReferralSheetState();
}

class _ReferralSheetState extends State<_ReferralSheet> {
  bool _codeCopied = false;
  bool _messageCopied = false;

  Future<void> _copy(String text, {required bool code}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => code ? _codeCopied = true : _messageCopied = true);
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    final reward = program.reward;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invita a un colega', style: text.headlineSmall),
            const SizedBox(height: ManoSpacing.xs),
            Text(
              reward == null
                  ? 'Comparte tu código con colegas que quieran trabajar en Mano.'
                  : 'Cuando se una con tu código ganas ${reward.coins} '
                        'Mano coins, que llegan a tu Billetera.',
              style: text.bodyMedium?.copyWith(color: ManoColors.muted),
            ),
            const SizedBox(height: ManoSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(ManoSpacing.md),
              decoration: BoxDecoration(
                color: ManoColors.sand,
                borderRadius: BorderRadius.circular(ManoRadius.card),
              ),
              child: Text(
                program.code,
                textAlign: TextAlign.center,
                style: text.headlineSmall,
              ),
            ),
            if (reward != null) ...[
              const SizedBox(height: ManoSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(ManoRadius.pill),
                child: LinearProgressIndicator(
                  value: reward.progress,
                  minHeight: 6,
                  color: ManoColors.flame,
                  backgroundColor: ManoColors.stone,
                ),
              ),
              const SizedBox(height: ManoSpacing.xs),
              Text(
                referralProgressText(reward),
                style: text.bodySmall?.copyWith(color: ManoColors.faint),
              ),
            ],
            const SizedBox(height: ManoSpacing.lg),
            ManoPrimaryButton(
              label: _codeCopied ? 'Código copiado' : 'Copiar código',
              onPressed: () => _copy(program.code, code: true),
            ),
            const SizedBox(height: ManoSpacing.sm),
            ManoOutlineButton(
              label: _messageCopied
                  ? 'Mensaje copiado'
                  : 'Copiar mensaje para compartir',
              onPressed: () =>
                  _copy(referralMessage(program.code), code: false),
            ),
            Center(
              child: ManoTextAction(
                label: 'Ver mi Billetera',
                onPressed: () => goToWallet(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
