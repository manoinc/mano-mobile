import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../identity_copy.dart';

/// Between the two sides of the cédula: the same tips, once more.
class BackIntroStep extends ConsumerWidget {
  const BackIntroStep({required this.state, super.key});

  final IdentityFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(identityFlowProvider.notifier);

    return ManoStepScaffold(
      onBack: notifier.back,
      headline: 'Ahora necesitamos una foto del reverso de tu cédula',
      headlineEmphasis: 'foto del reverso',
      subhead: 'Sigue las mismas recomendaciones para tomar una buena foto:',
      progress: state.progress,
      primaryLabel: 'Continuar',
      onPrimary: notifier.begin,
      children: const [ManoTipList(tips: photoTips)],
    );
  }
}
