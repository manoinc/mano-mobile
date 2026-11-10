import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

const _meanwhile =
    'Mientras tanto puedes completar tu perfil y conocer la app. Podrás '
    'publicar servicios y recibir solicitudes cuando tu cuenta esté aprobada.';

/// Submitted: in review if the identity photos went out; otherwise, asks for them.
class PendingStep extends ConsumerWidget {
  const PendingStep({
    required this.onExplore,
    required this.onVerifyIdentity,
    super.key,
  });

  final VoidCallback onExplore;
  final VoidCallback onVerifyIdentity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final sent = switch (ref.watch(identityFlowProvider).step) {
      IdentityFlowStep.pending || IdentityFlowStep.approved => true,
      _ => false,
    };

    if (sent) {
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
          Text(_meanwhile, style: text.bodyLarge),
        ],
      );
    }
    return ManoStepScaffold(
      headline: 'Falta verificar tu identidad',
      headlineEmphasis: 'verificar tu identidad',
      subhead:
          'Aún no nos has enviado las fotos de tu cédula y tu selfie. Sin '
          'ellas no podemos revisar tu cuenta.',
      primaryLabel: 'Verificar mi identidad',
      onPrimary: onVerifyIdentity,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: ManoStatusChip(
            label: 'Sin verificar',
            tone: ManoStatusTone.neutral,
          ),
        ),
        const SizedBox(height: ManoSpacing.lg),
        Text(_meanwhile, style: text.bodyLarge),
        const SizedBox(height: ManoSpacing.lg),
        ManoQuietButton(label: 'Explorar la app', onPressed: onExplore),
      ],
    );
  }
}
