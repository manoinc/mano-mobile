import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// Airbnb-style price details: labelled lines, a rule, then the total.
class ManoPriceBreakdown extends StatelessWidget {
  const ManoPriceBreakdown({
    required this.title,
    required this.lines,
    required this.totalLabel,
    required this.totalValue,
    super.key,
  });

  final String title;

  /// Pre-formatted (label, amount) pairs.
  final List<(String, String)> lines;
  final String totalLabel;
  final String totalValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final strong = textTheme.titleSmall;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ManoRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: ManoSpacing.md),
            for (final (label, value) in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
                child: _Line(label, value, style: textTheme.bodyMedium),
              ),
            Divider(
              height: ManoSpacing.lg,
              color: theme.colorScheme.outlineVariant,
            ),
            _Line(totalLabel, totalValue, style: strong),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {required this.style});

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(label, style: style)),
      const SizedBox(width: ManoSpacing.md),
      Text(value, style: style),
    ],
  );
}
