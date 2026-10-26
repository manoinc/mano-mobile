import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../onboarding_copy.dart';
import '../sign_in_sheet.dart';

/// The front door: create a professional account or sign in to one.
class WelcomeStep extends ConsumerStatefulWidget {
  const WelcomeStep({super.key});

  @override
  ConsumerState<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends ConsumerState<WelcomeStep> {
  @override
  Widget build(BuildContext context) {
    final failure = switch (ref.watch(sessionProvider).value) {
      SignedOut(:final lastFailure) => lastFailure,
      _ => null,
    };

    return ManoHeroScaffold(
      headline: 'Tu oficio, más cerca de tus clientes.',
      primaryLabel: 'Crear cuenta profesional',
      onPrimary: ref.read(providerOnboardingProvider.notifier).start,
      secondaryLabel: 'Ya tengo cuenta',
      onSecondary: () => showSignInSheet(context, ref),
      footnote:
          'Con Mano Profesionales recibes solicitudes de hogares en tu zona. '
          'Verificamos tu identidad antes de que publiques servicios.',
      notice: failure == null
          ? null
          : ManoNotice(
              message: authFailureCopy(failure),
              tone: authFailureTone(failure),
              onDismiss: () =>
                  ref.read(sessionProvider.notifier).acknowledgeFailure(),
            ),
    );
  }
}
