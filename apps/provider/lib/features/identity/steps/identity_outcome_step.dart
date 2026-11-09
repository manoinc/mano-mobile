import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Where the check stands once sent: pending, approved, or refused.
class IdentityOutcomeStep extends ConsumerWidget {
  const IdentityOutcomeStep({
    required this.state,
    required this.onDone,
    this.onLater,
    super.key,
  });

  final IdentityFlowState state;
  final VoidCallback onDone;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(identityFlowProvider.notifier);
    final text = Theme.of(context).textTheme;

    return switch (state.step) {
      IdentityFlowStep.rejected => ManoStepScaffold(
        headline: 'No pudimos verificar tu identidad',
        subhead: 'Toma las fotos de nuevo con esto en cuenta:',
        trailingLabel: onLater == null ? null : 'Ahora no',
        onTrailing: onLater,
        primaryLabel: 'Intentar de nuevo',
        onPrimary: notifier.retry,
        children: [
          ManoNotice(
            message: state.rejection ?? '',
            tone: ManoNoticeTone.warning,
          ),
        ],
      ),
      IdentityFlowStep.approved => ManoStepScaffold(
        headline: 'Tu identidad está verificada',
        headlineEmphasis: 'verificada',
        subhead: 'Tus clientes verán la insignia en tu perfil.',
        primaryLabel: 'Continuar',
        onPrimary: onDone,
        children: const [
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.verified, size: 48, color: ManoColors.clay),
          ),
        ],
      ),
      _ => ManoStepScaffold(
        headline: 'Estamos revisando tus documentos',
        subhead:
            'Te avisaremos cuando terminemos; suele tomar menos de un día.',
        primaryLabel: 'Continuar',
        onPrimary: onDone,
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
            'Mientras tanto puedes seguir creando tu perfil.',
            style: text.bodyLarge,
          ),
        ],
      ),
    };
  }
}
