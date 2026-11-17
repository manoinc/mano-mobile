import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'steps/brief_step.dart';
import 'steps/identity_intro_step.dart';
import 'steps/identity_outcome_step.dart';

/// The identity check, one screen per step; the host decides where it leads.
class IdentityFlowView extends ConsumerWidget {
  const IdentityFlowView({required this.onDone, this.onLater, super.key});

  /// Leaves once Didit has the photos, or the check is already settled.
  final VoidCallback onDone;

  /// Puts the check off; offered only when set.
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(identityFlowProvider);
    final step = state.step;

    return ManoStepTransition(
      index: step.index,
      child: switch (step) {
        IdentityFlowStep.loading => const Scaffold(
          key: ValueKey('loading'),
          body: Center(child: ManoLoader()),
        ),
        IdentityFlowStep.intro => IdentityIntroStep(
          key: const ValueKey('intro'),
          state: state,
          onLater: onLater,
        ),
        IdentityFlowStep.frontBrief ||
        IdentityFlowStep.backBrief ||
        IdentityFlowStep.selfieBrief => BriefStep(
          key: ValueKey(step),
          state: state,
        ),
        IdentityFlowStep.pending ||
        IdentityFlowStep.approved ||
        IdentityFlowStep.rejected => IdentityOutcomeStep(
          key: ValueKey(step),
          state: state,
          onDone: onDone,
          onLater: onLater,
        ),
      },
    );
  }
}
