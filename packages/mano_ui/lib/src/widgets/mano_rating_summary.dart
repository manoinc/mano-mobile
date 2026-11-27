import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A provider's standing at a glance: big average, its stars and the count.
class ManoRatingSummary extends StatelessWidget {
  const ManoRatingSummary({
    required this.average,
    required this.averageLabel,
    required this.countLabel,
    this.emptyLabel = 'Aún sin reseñas',
    super.key,
  });

  /// Out of five; null before the first review.
  final double? average;

  /// The average as the screen writes it, e.g. "4,9".
  final String averageLabel;

  /// E.g. "32 reseñas".
  final String countLabel;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final average = this.average;
    if (average == null) {
      return Text(
        emptyLabel,
        style: theme.titleMedium?.copyWith(color: context.palette.muted),
      );
    }
    return Semantics(
      label: '$averageLabel de 5 estrellas, $countLabel',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(averageLabel, style: theme.displaySmall),
            const SizedBox(width: ManoSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        _starFor(average, i),
                        size: 18,
                        color: context.palette.clay,
                      ),
                  ],
                ),
                const SizedBox(height: ManoSpacing.xs),
                Text(
                  countLabel,
                  style: theme.bodySmall?.copyWith(
                    color: context.palette.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Half a star from .25 up, a whole one from .75.
  static IconData _starFor(double average, int position) {
    final fill = average - (position - 1);
    if (fill >= 0.75) return Icons.star_rounded;
    if (fill >= 0.25) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }
}
