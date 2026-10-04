import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../onboarding_copy.dart';

/// The front door: create a professional account or sign in to one.
class WelcomeStep extends ConsumerStatefulWidget {
  const WelcomeStep({super.key});

  @override
  ConsumerState<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends ConsumerState<WelcomeStep> {
  // Waiting on sign-in belongs to this button, not to the session.
  bool _busy = false;

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).signIn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final failure = switch (ref.watch(sessionProvider).value) {
      SignedOut(:final lastFailure) => lastFailure,
      _ => null,
    };

    return ManoHeroScaffold(
      headline: 'Tu oficio, más cerca de tus clientes.',
      primaryLabel: 'Crear cuenta profesional',
      onPrimary: _busy
          ? null
          : ref.read(providerOnboardingProvider.notifier).start,
      secondaryLabel: 'Ya tengo cuenta',
      onSecondary: _signIn,
      busy: _busy,
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
