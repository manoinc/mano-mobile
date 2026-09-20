import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// Slide 3: what Mano is, and the ways in.
///
/// The actions live in the carousel's bottom bar, not here.
class SlideWelcome extends StatelessWidget {
  const SlideWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: ManoSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: ManoSpacing.md),
          // Constrained rather than left to its own 800px: the file has no
          // 2x/3x variants, so Flutter would read it as logical pixels.
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: Image.asset(
              'assets/illustrations/mano-home-tools.webp',
              fit: BoxFit.contain,
              semanticLabel: 'Una casa rodeada de herramientas',
            ),
          ),
          const SizedBox(height: ManoSpacing.lg),
          Text(
            'Tu casa, en buenas manos.',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: ManoSpacing.sm),
          Text(
            'Encuentra profesionales cerca de ti para arreglar, instalar y '
            'mantener lo que necesites.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: ManoColors.muted,
            ),
          ),
          const SizedBox(height: ManoSpacing.lg),
        ],
      ),
    );
  }
}
