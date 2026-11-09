import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../onboarding_copy.dart';

/// Optional certificates; the cédula went through the identity check.
class DocumentsStep extends ConsumerWidget {
  const DocumentsStep({required this.state, super.key});

  final ProviderOnboardingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(providerOnboardingProvider.notifier);

    return ManoStepScaffold(
      onBack: notifier.back,
      headline: 'Tus certificados',
      subhead: 'Cursos, licencias o cartas que respalden tu trabajo.',
      progress: state.progress,
      primaryLabel: 'Continuar',
      onPrimary: state.documentsComplete ? notifier.next : null,
      children: [
        for (final document in ProviderDocument.values) ...[
          _DocumentRow(
            label: documentLabel(document),
            required: document.required,
            attached: state.attached.containsKey(document),
            onAttach: () => notifier.attach(document),
          ),
          const Divider(height: 1, color: ManoColors.stone),
        ],
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.label,
    required this.required,
    required this.attached,
    required this.onAttach,
  });

  final String label;
  final bool required;
  final bool attached;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ManoSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.titleSmall),
                if (required)
                  Text(
                    'Obligatorio',
                    style: text.bodySmall?.copyWith(color: ManoColors.faint),
                  ),
              ],
            ),
          ),
          if (attached)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: ManoColors.ink,
                ),
                const SizedBox(width: ManoSpacing.xs),
                Text('Adjuntado', style: text.labelLarge),
              ],
            )
          else
            ManoTextAction(label: 'Adjuntar', onPressed: onAttach),
        ],
      ),
    );
  }
}
