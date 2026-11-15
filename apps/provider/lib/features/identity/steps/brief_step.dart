import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../identity_copy.dart';

/// One brief, Nu-style: the picture, one line; the selfie's Empezar opens Didit.
class BriefStep extends ConsumerWidget {
  const BriefStep({required this.state, super.key});

  final IdentityFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(identityFlowProvider.notifier);
    final copy = briefCopy(state.step);
    final last = state.step == IdentityFlowStep.selfieBrief;

    return ManoIllustratedStep(
      illustration: Image.asset(
        copy.art,
        fit: BoxFit.cover,
        // The back crops toward the table, where the cédula lies.
        alignment: state.step == IdentityFlowStep.backBrief
            ? Alignment.bottomCenter
            : Alignment.topCenter,
        excludeFromSemantics: true,
      ),
      onBack: notifier.back,
      headline: copy.text,
      headlineEmphasis: copy.emphasis,
      notice: switch (state.failure) {
        final failure? => ManoNotice(
          message: failure.message,
          tone: ManoNoticeTone.error,
          onDismiss: notifier.acknowledgeFailure,
        ),
        null => null,
      },
      primaryLabel: last ? 'Empezar' : 'Continuar',
      onPrimary: last ? notifier.start : notifier.next,
      busy: state.busy,
    );
  }
}
