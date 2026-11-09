import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';

import 'identity_flow_view.dart';

/// The identity check on its own, opened from Perfil.
class IdentityScreen extends ConsumerWidget {
  const IdentityScreen({super.key});

  // Steps that system back walks within, rather than leaving the screen.
  static const _inner = {
    IdentityFlowStep.cedulaFront,
    IdentityFlowStep.cedulaBack,
    IdentityFlowStep.selfie,
    IdentityFlowStep.review,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(identityFlowProvider.select((s) => s.step));
    return PopScope(
      canPop: !_inner.contains(step),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(identityFlowProvider.notifier).back();
      },
      child: IdentityFlowView(
        onDone: () => context.pop(),
        onLater: () => context.pop(),
      ),
    );
  }
}
