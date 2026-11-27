import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// One figure and what it measures, on a quiet raised tile.
class ManoStatTile extends StatelessWidget {
  const ManoStatTile({
    required this.value,
    required this.label,
    this.icon,
    super.key,
  });

  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(ManoSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.sand,
        borderRadius: BorderRadius.circular(ManoRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  style: text.headlineSmall?.copyWith(
                    color: context.palette.ink,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: ManoSpacing.xs),
                Icon(icon, size: 18, color: context.palette.ink),
              ],
            ],
          ),
          const SizedBox(height: ManoSpacing.xs),
          Text(
            label,
            style: text.bodySmall?.copyWith(color: context.palette.muted),
          ),
        ],
      ),
    );
  }
}
