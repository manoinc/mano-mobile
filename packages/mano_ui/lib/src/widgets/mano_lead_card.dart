import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// An open project a professional may quote on; the client stays hidden.
class ManoLeadCard extends StatelessWidget {
  const ManoLeadCard({
    required this.title,
    required this.categoryLabel,
    required this.ageLabel,
    required this.budgetLabel,
    required this.costLabel,
    required this.onTap,
    super.key,
  });

  final String title;
  final String categoryLabel;

  /// Pre-formatted, e.g. "hace 5h".
  final String ageLabel;

  /// Pre-formatted, e.g. "Presupuesto $1.800.000" or "Sin presupuesto".
  final String budgetLabel;

  /// What quoting costs, e.g. "Gratis".
  final String costLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ManoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: context.palette.ink,
                ),
              ),
              const SizedBox(height: ManoSpacing.xs),
              Text(
                '$categoryLabel · $ageLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: context.palette.muted,
                ),
              ),
              const SizedBox(height: ManoSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      budgetLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: context.palette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: ManoSpacing.sm),
                  Text(
                    costLabel,
                    style: textTheme.labelLarge?.copyWith(
                      color: context.palette.clay,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
