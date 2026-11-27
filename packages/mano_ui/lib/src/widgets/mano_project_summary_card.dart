import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_status_chip.dart';

/// A posted project in a list: what it is, and where it stands.
class ManoProjectSummaryCard extends StatelessWidget {
  const ManoProjectSummaryCard({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusTone,
    this.trailingLabel,
    this.onTap,
    super.key,
  });

  final String title;

  /// Pre-formatted, e.g. "Pintura · hace 5h".
  final String subtitle;

  /// e.g. "3 cotizaciones" or "Esperando cotizaciones".
  final String statusLabel;
  final ManoStatusTone statusTone;

  /// Beside the status, e.g. "desde $1.450.000"; null leaves it out.
  final String? trailingLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trailing = trailingLabel;

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
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: context.palette.muted,
                ),
              ),
              const SizedBox(height: ManoSpacing.sm),
              Row(
                children: [
                  Flexible(
                    child: ManoStatusChip(label: statusLabel, tone: statusTone),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: ManoSpacing.sm),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          trailing,
                          style: textTheme.titleSmall?.copyWith(
                            color: context.palette.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
