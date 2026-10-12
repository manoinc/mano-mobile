import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'wallet_labels.dart';

Future<void> showHowItWorksSheet(BuildContext context) =>
    showManoSheet<void>(context: context, builder: (_) => const _HowItWorks());

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cómo funcionan los coins', style: textTheme.headlineSmall),
            const SizedBox(height: ManoSpacing.sm),
            Text(
              'Ver solicitudes es gratis. Pagas coins solo cuando aceptas una; '
              'si algo falla, te los devolvemos.',
              style: textTheme.bodyLarge?.copyWith(color: ManoColors.muted),
            ),
            const SizedBox(height: ManoSpacing.md),
            for (final category in ServiceCategories.all)
              ManoDetailRow(
                label: category.label,
                value: coinsLabel(LeadPricing.costFor(category.id)),
              ),
          ],
        ),
      ),
    );
  }
}
