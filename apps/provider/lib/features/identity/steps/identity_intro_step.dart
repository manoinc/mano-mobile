import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../identity_copy.dart';

/// Why the photos are needed, and how to take them well.
class IdentityIntroStep extends ConsumerWidget {
  const IdentityIntroStep({required this.state, this.onLater, super.key});

  final IdentityFlowState state;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(identityFlowProvider.notifier);
    final text = Theme.of(context).textTheme;

    return ManoStepScaffold(
      trailingLabel: onLater == null ? null : 'Ahora no',
      onTrailing: onLater,
      headline: 'Vamos a tomar fotos de tu cédula para confirmar tu identidad',
      headlineEmphasis: 'confirmar tu identidad',
      subhead:
          'Ten a mano tu cédula de ciudadanía. Así tus clientes saben '
          'quién llega a su casa.',
      progress: state.progress,
      primaryLabel: 'Continuar',
      onPrimary: notifier.next,
      children: [
        if (state.failure case final failure?) ...[
          ManoNotice(
            message: failure.message,
            tone: ManoNoticeTone.error,
            onDismiss: notifier.acknowledgeFailure,
          ),
          const SizedBox(height: ManoSpacing.lg),
        ],
        Text(
          'Sigue estos consejos para que tu cédula se vea bien en la foto:',
          style: text.bodyLarge?.copyWith(color: ManoColors.muted),
        ),
        const SizedBox(height: ManoSpacing.md),
        const ManoTipList(tips: photoTips),
      ],
    );
  }
}
