import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'profile_labels.dart';
import 'provider_profile_screen.dart';

Future<void> showReferralSheet(BuildContext context, ReferralProgram program) =>
    showManoSheet<void>(
      context: context,
      builder: (_) => _ReferralSheet(program: program),
    );

class _ReferralSheet extends ConsumerStatefulWidget {
  const _ReferralSheet({required this.program});

  final ReferralProgram program;

  @override
  ConsumerState<_ReferralSheet> createState() => _ReferralSheetState();
}

class _ReferralSheetState extends ConsumerState<_ReferralSheet> {
  bool _codeCopied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.program.code));
    if (!mounted) return;
    setState(() => _codeCopied = true);
  }

  Future<void> _share() {
    final code = widget.program.code;
    final link = ref.read(manoConfigProvider).inviteLink(code);
    return ref.read(textSharerProvider)(referralMessage(code, link));
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    final coins = program.coinsPerColleague;
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
              coins == null
                  ? 'Comparte tu código con colegas que quieran trabajar en Mano.'
                  : 'Cuando un colega se une con tu código y verifica su '
                        'identidad, ganas $coins Mano coins en tu Billetera.',
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
            if (program.invited > 0) ...[
              const SizedBox(height: ManoSpacing.sm),
              Text(
                referralCountText(program.invited, program.verified),
                style: text.bodySmall?.copyWith(color: ManoColors.faint),
              ),
            ],
            const SizedBox(height: ManoSpacing.lg),
            ManoPrimaryButton(label: 'Compartir mi código', onPressed: _share),
            const SizedBox(height: ManoSpacing.sm),
            ManoOutlineButton(
              label: _codeCopied ? 'Código copiado' : 'Copiar código',
              onPressed: _copy,
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
