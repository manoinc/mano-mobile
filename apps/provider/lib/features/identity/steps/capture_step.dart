import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../identity_copy.dart';

/// One photo on the camera's dark ground: guide, hint, and the shutter.
class CaptureStep extends ConsumerWidget {
  const CaptureStep({required this.state, super.key});

  final IdentityFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(identityFlowProvider.notifier);
    final kind = state.step.kind!;
    final taken = state.photos[kind];
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: ManoColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ManoSpacing.lg,
            0,
            ManoSpacing.lg,
            ManoSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: state.busy ? null : notifier.back,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  iconSize: 20,
                  color: ManoColors.sand,
                  tooltip: 'Atrás',
                ),
              ),
              const SizedBox(height: ManoSpacing.sm),
              Expanded(
                child: ManoCaptureFrame(
                  instruction: captureInstruction(kind),
                  shape: kind == IdentityDocumentKind.selfie
                      ? ManoCaptureShape.face
                      : ManoCaptureShape.card,
                  preview: taken == null
                      ? null
                      : Image.memory(taken.bytes, fit: BoxFit.cover),
                  helpLabel: 'Ayuda',
                  onHelp: () => _showHelp(context),
                ),
              ),
              const SizedBox(height: ManoSpacing.md),
              Text(
                captureHint(kind),
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: ManoColors.sand),
              ),
              if (state.failure case final failure?) ...[
                const SizedBox(height: ManoSpacing.md),
                ManoNotice(
                  message: failure.message,
                  tone: ManoNoticeTone.error,
                  onDismiss: notifier.acknowledgeFailure,
                ),
              ],
              const SizedBox(height: ManoSpacing.md),
              ManoPrimaryButton(
                label: 'Tomar foto',
                busy: state.busy,
                onPressed: notifier.capture,
              ),
            ],
          ),
        ),
      ),
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
          label: 'Entendido',
          onPressed: () => Navigator.of(sheet).pop(),
        ),
      ],
    ),
  ),
);
