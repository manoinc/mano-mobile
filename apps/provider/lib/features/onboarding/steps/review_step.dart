import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../onboarding_copy.dart';

/// Everything entered so far, and the submission for review.
class ReviewStep extends ConsumerWidget {
  const ReviewStep({required this.state, super.key});

  final ProviderOnboardingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(providerOnboardingProvider.notifier);
    final draft = state.draft;
    final submitting = state.status is ProviderOnboardingSubmitting;

    return ManoStepScaffold(
      onBack: submitting ? null : notifier.back,
      headline: 'Revisa y envía',
      subhead: 'Puedes volver atrás para corregir cualquier dato.',
      primaryLabel: 'Enviar a revisión',
      onPrimary: notifier.submit,
      busy: submitting,
      children: [
        if (state.status case ProviderOnboardingFailed(:final failure)) ...[
          ManoNotice(
            message: failure.message,
            tone: ManoNoticeTone.error,
            onDismiss: notifier.acknowledgeFailure,
          ),
          const SizedBox(height: ManoSpacing.lg),
        ],
        _SummaryRow(label: 'Nombre', value: draft.displayName),
        _SummaryRow(label: 'Celular', value: draft.phone),
        _SummaryRow(label: 'Zona de cobertura', value: draft.workZone),
        _SummaryRow(
          label: 'Servicios',
          value: draft.categories.map(ServiceCategories.labelOf).join(', '),
        ),
        _SummaryRow(
          label: 'Experiencia',
          value: draft.yearsExperience == 1
              ? '1 año'
              : '${draft.yearsExperience} años',
        ),
        if (draft.bio.isNotEmpty)
          _SummaryRow(label: 'Descripción', value: draft.bio),
        _SummaryRow(
          label: 'Documentos',
          value: [
            for (final d in ProviderDocument.values)
              if (state.attached.containsKey(d)) documentLabel(d),
          ].join('\n'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: ManoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.labelMedium?.copyWith(color: ManoColors.faint),
          ),
          const SizedBox(height: ManoSpacing.xs),
          Text(value, style: text.titleMedium),
        ],
      ),
    );
  }
}
