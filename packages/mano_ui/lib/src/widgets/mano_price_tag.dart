import 'package:flutter/material.dart';

/// A price with its rate, e.g. "$45.000" + "/hora"; both arrive pre-formatted.
class ManoPriceTag extends StatelessWidget {
  const ManoPriceTag({
    required this.amountLabel,
    required this.rateLabel,
    this.large = false,
    super.key,
  });

  final String amountLabel;
  final String rateLabel;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          amountLabel,
          style: (large ? textTheme.headlineSmall : textTheme.titleMedium)
              ?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 4),
        Text(
          rateLabel,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
