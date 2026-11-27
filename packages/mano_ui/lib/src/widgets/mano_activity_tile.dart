import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// One line of an activity list: a round icon, two lines of text and a signed amount.
class ManoActivityTile extends StatelessWidget {
  const ManoActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.positive,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Pre-signed, e.g. "+30" or "-3".
  final String amountLabel;

  /// Credits read in ink, spends in muted grey.
  final bool positive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ManoSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: context.palette.stone,
              child: Icon(icon, color: context.palette.ink, size: 20),
            ),
            const SizedBox(width: ManoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: context.palette.faint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: ManoSpacing.sm),
            Text(
              amountLabel,
              style: textTheme.titleMedium?.copyWith(
                color: positive ? context.palette.ink : context.palette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
