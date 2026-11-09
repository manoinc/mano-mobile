import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../identity_copy.dart';

/// The three photos side by side with the cédula, and the send.
class IdentityReviewStep extends ConsumerWidget {
  const IdentityReviewStep({required this.state, super.key});

  final IdentityFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(identityFlowProvider.notifier);

    return ManoStepScaffold(
      onBack: state.busy ? null : notifier.back,
      headline: 'Revisa tus fotos',
      subhead: 'Que los datos se lean y tu cara se vea completa.',
      progress: state.progress,
      primaryLabel: 'Enviar',
      onPrimary: notifier.send,
      busy: state.busy,
      children: [
        if (state.failure case final failure?) ...[
          ManoNotice(
            message: failure.message,
            tone: ManoNoticeTone.error,
            onDismiss: notifier.acknowledgeFailure,
          ),
          const SizedBox(height: ManoSpacing.lg),
        ],
        for (final kind in IdentityDocumentKind.values)
          if (state.photos[kind] case final photo?)
            ManoCaptureReviewRow(
              image: Image.memory(photo.bytes, fit: BoxFit.cover),
              label: documentName(kind),
              actionLabel: 'Repetir',
              onAction: state.busy ? null : () => notifier.retake(kind),
            ),
      ],
    );
  }
}
