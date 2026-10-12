import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// How far one of my messages got: out, on their phone, or seen.
enum ManoReceipt { sent, delivered, read }

/// One chat message; [mine] puts it on the right in ink.
///
/// Bubbles in a run from one sender tighten the corners they share, so the run
/// reads as one block: [isFirstInGroup] and [isLastInGroup] say where this one
/// sits. The time and receipt belong to the run, so only the last bubble gets a
/// [timeLabel].
class ManoChatBubble extends StatelessWidget {
  const ManoChatBubble({
    required this.text,
    required this.mine,
    this.timeLabel,
    this.receipt,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    super.key,
  });

  final String text;
  final bool mine;

  /// `null` hides the time, for a bubble that is not last in its group.
  final String? timeLabel;

  /// Shown beside the time on my messages only.
  final ManoReceipt? receipt;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  BorderRadius get _radius {
    const round = Radius.circular(ManoRadius.lg);
    const tight = Radius.circular(ManoRadius.sm);
    final top = isFirstInGroup ? round : tight;
    final bottom = isLastInGroup ? round : tight;
    return mine
        ? BorderRadius.only(
            topLeft: round,
            bottomLeft: round,
            topRight: top,
            bottomRight: bottom,
          )
        : BorderRadius.only(
            topRight: round,
            bottomRight: round,
            topLeft: top,
            bottomLeft: bottom,
          );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = mine ? Colors.white : ManoColors.ink;
    final quiet = mine ? ManoColors.stone : ManoColors.faint;
    final time = timeLabel;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: DecoratedBox(
          key: const Key('chat-bubble-body'),
          decoration: BoxDecoration(
            color: mine ? ManoColors.ink : ManoColors.sand,
            borderRadius: _radius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ManoSpacing.md,
              vertical: ManoSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: textTheme.bodyMedium?.copyWith(color: foreground),
                ),
                if (time != null)
                  Padding(
                    padding: const EdgeInsets.only(top: ManoSpacing.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          key: const Key('chat-bubble-time'),
                          style: textTheme.labelSmall?.copyWith(color: quiet),
                        ),
                        if (mine && receipt != null) ...[
                          const SizedBox(width: ManoSpacing.xs),
                          _Receipt(receipt: receipt!),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Signal-style circle: outlined once sent, filled once delivered, flame once read.
class _Receipt extends StatelessWidget {
  const _Receipt({required this.receipt});

  final ManoReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (receipt) {
      ManoReceipt.sent => (
        Icons.check_circle_outline_rounded,
        ManoColors.stone,
        'Enviado',
      ),
      ManoReceipt.delivered => (
        Icons.check_circle_rounded,
        ManoColors.stone,
        'Entregado',
      ),
      ManoReceipt.read => (
        Icons.check_circle_rounded,
        ManoColors.flame,
        'Leído',
      ),
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Icon(
        icon,
        key: Key('chat-receipt-${receipt.name}'),
        size: 14,
        color: color,
      ),
    );
  }
}
