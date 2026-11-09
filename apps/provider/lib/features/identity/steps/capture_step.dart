import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../identity_art.dart';
import '../identity_copy.dart';

/// One photo, Nu-style: the picture, one line, and Tomar foto opens the camera.
class CaptureStep extends ConsumerWidget {
  const CaptureStep({required this.state, super.key});

  final IdentityFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(identityFlowProvider.notifier);
    final kind = state.step.kind!;
    final headline = captureHeadline(kind);
    final isCedula = kind != IdentityDocumentKind.selfie;

    return ManoIllustratedStep(
      illustration: identityArt(kind),
      onBack: notifier.back,
      headline: headline.text,
      headlineEmphasis: headline.emphasis,
      notice: switch (state.failure) {
        final failure? => ManoNotice(
          message: failure.message,
          tone: ManoNoticeTone.error,
          onDismiss: notifier.acknowledgeFailure,
        ),
        null => null,
      },
      primaryLabel: 'Tomar foto',
      onPrimary: notifier.capture,
      secondaryLabel: isCedula ? 'Ayuda' : null,
      onSecondary: isCedula ? () => _showHelp(context) : null,
      busy: state.busy,
    );
  }
}

/// The usual reasons a photo comes back unreadable.
Future<void> _showHelp(BuildContext context) => showManoSheet<void>(
  context: context,
  builder: (sheet) => Padding(
    padding: const EdgeInsets.all(ManoSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Errores comunes', style: Theme.of(sheet).textTheme.titleLarge),
        const SizedBox(height: ManoSpacing.md),
        const ManoTipList(tips: commonMistakes),
        const SizedBox(height: ManoSpacing.lg),
        ManoPrimaryButton(
          label: 'Ok, entendido',
          onPressed: () => Navigator.of(sheet).pop(),
        ),
      ],
    ),
  ),
);
