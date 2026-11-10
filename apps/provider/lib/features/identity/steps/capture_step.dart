import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../camera/capture_camera_provider.dart';
import '../camera/identity_camera_screen.dart';
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

    Future<void> shoot() async {
      final photo = await openIdentityCamera(
        context,
        kind: kind,
        facing: state.step.facing!,
        camera: ref.read(captureCameraProvider)(),
      );
      if (photo != null) await notifier.usePhoto(photo);
    }

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
      onPrimary: shoot,
      busy: state.busy,
    );
  }
}
