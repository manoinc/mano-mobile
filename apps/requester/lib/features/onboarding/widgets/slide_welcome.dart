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
          const SizedBox(height: ManoSpacing.xl),
          Text(
            'Tu casa, en buenas manos.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: ManoSpacing.sm),
          Text(
            'Encuentra profesionales cerca de ti para arreglar, instalar y '
            'mantener lo que necesites.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: context.palette.muted,
            ),
          ),
          const SizedBox(height: ManoSpacing.xl),
          // The file has no 2x/3x variants, so it is constrained rather than left to its pixel size.
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            // The art sits on white; the card corner frames it on a dark page.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ManoRadius.card),
              child: Image.asset(
                'assets/illustrations/mano-sticky-tasks.webp',
                fit: BoxFit.contain,
                semanticLabel: 'Notas adhesivas con tareas del hogar',
              ),
            ),
          ),
          const SizedBox(height: ManoSpacing.lg),
        ],
      ),
    );
  }
}
