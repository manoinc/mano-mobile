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
  void _openSignIn() {
    showManoSheet<void>(
      context: context,
      builder: (sheet) => ManoCredentialsSheet(
        title: 'Inicia sesión',
        message: 'Con el correo de tu cuenta profesional.',
        submitLabel: 'Entrar',
        onSubmit: (email, password) => _signIn(sheet, email, password),
      ),
    );
  }

  // Resolves to the copy to show inside the sheet, or closes it on success.
  Future<String?> _signIn(BuildContext sheet, String email, String password) async {
    // Captured first: a successful sign-in replaces this screen, and its ref with it.
    final session = ref.read(sessionProvider.notifier);
    final failure = await session.signIn(
      Credentials(email: email, password: password),
    );
    if (failure != null) {
      session.acknowledgeFailure();
      return authFailureCopy(failure);
    }
    if (sheet.mounted) Navigator.of(sheet).pop();
    return null;
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
      onPrimary: ref.read(providerOnboardingProvider.notifier).start,
      secondaryLabel: 'Ya tengo cuenta',
      onSecondary: _openSignIn,
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
