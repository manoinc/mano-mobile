import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// How a status reads; screens map their domain status onto one of these.
enum ManoStatusTone { info, warning, success, neutral }

/// A small pill naming a status, e.g. "Programado".
class ManoStatusChip extends StatelessWidget {
  const ManoStatusChip({required this.label, required this.tone, super.key});

  final String label;
  final ManoStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Green has no brand token, but reads as "done" everywhere; flame is kept for the primary action.
    final (background, foreground) = switch (tone) {
      ManoStatusTone.info || ManoStatusTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
      ),
      ManoStatusTone.warning => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      ManoStatusTone.success =>
        scheme.brightness == Brightness.light
            ? (Colors.green.shade100, Colors.green.shade900)
            : (Colors.green.shade900, Colors.green.shade100),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ManoSpacing.sm,
        vertical: ManoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ManoRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: foreground),
      ),
    );
  }
}
