import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// One chat message; [mine] puts it on the right in ink.
class ManoChatBubble extends StatelessWidget {
  const ManoChatBubble({
    required this.text,
    required this.timeLabel,
    required this.mine,
    super.key,
  });

  final String text;
  final String timeLabel;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = mine ? Colors.white : ManoColors.ink;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: ManoSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: ManoSpacing.md,
            vertical: ManoSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: mine ? ManoColors.ink : ManoColors.sand,
            borderRadius: BorderRadius.circular(ManoRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: textTheme.bodyMedium?.copyWith(color: foreground),
              ),
              const SizedBox(height: 2),
              Text(
                timeLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: mine ? ManoColors.stone : ManoColors.faint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
