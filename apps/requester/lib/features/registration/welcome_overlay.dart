import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// Step 4: the thank-you, over the home screen.
class WelcomeOverlay extends StatelessWidget {
  const WelcomeOverlay({required this.onStart, super.key});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ManoDialogCard(
      art: const ManoMonogram(height: 44, color: ManoColors.flame),
      title: '¡Gracias por unirte a Mano!',
      message:
          'Estamos aquí para ayudarte a resolver los pendientes de tu hogar '
          'de forma fácil, económica y sin estrés.',
      primaryLabel: '¡Empecemos!',
      onPrimary: onStart,
    );
  }
}
