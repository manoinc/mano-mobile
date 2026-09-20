import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A booked job: who is coming, for what, when, and what it costs.
///
/// The price is a plain string so the card never has to know a currency or a
/// separator.
class ManoBookingCard extends StatelessWidget {
  const ManoBookingCard({
    required this.avatar,
    required this.name,
    required this.task,
    required this.when,
    required this.price,
    super.key,
  });

  final Widget avatar;
  final String name;
  final String task;
  final String when;
  final String price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(ManoSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(ManoRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: ManoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ManoColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ManoSpacing.md),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 15,
                color: ManoColors.faint,
              ),
              const SizedBox(width: ManoSpacing.xs + 2),
              Expanded(
                child: Text(
                  when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ManoColors.faint,
                  ),
                ),
              ),
              const SizedBox(width: ManoSpacing.sm),
              Text(price, style: theme.textTheme.titleSmall),
            ],
          ),
        ],
      ),
    );
  }
}
