import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// Submitted: the account waits for staff review.
class PendingStep extends StatelessWidget {
  const PendingStep({required this.onExplore, super.key});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ManoStepScaffold(
      headline: 'Tu cuenta está en revisión',
      subhead:
          'Nuestro equipo está verificando tus documentos. Te avisaremos '
          'cuando terminemos.',
      primaryLabel: 'Explorar la app',
      onPrimary: onExplore,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: ManoStatusChip(
            label: 'En revisión',
            tone: ManoStatusTone.warning,
          ),
        ),
        const SizedBox(height: ManoSpacing.lg),
        Text(
          'Mientras tanto puedes completar tu perfil y conocer la app. '
          'Podrás publicar servicios y recibir solicitudes cuando tu cuenta '
          'esté aprobada.',
          style: text.bodyLarge,
        ),
      ],
    );
  }
}
