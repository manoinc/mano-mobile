import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// The message list, newest pinned to the bottom, with a label per day.
class ChatThreadView extends StatelessWidget {
  const ChatThreadView({required this.items, required this.onRetry, super.key});

  final List<ChatThreadItem> items;
  final ValueChanged<String> onRetry;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    DateTime? previous;
    for (final item in items) {
      if (previous == null || !_sameDay(previous, item.sentAt)) {
        rows.add(_DaySeparator(label: ManoFormat.dayMonth(item.sentAt)));
      }
      previous = item.sentAt;
      rows.add(_row(context, item));
    }
    final newestFirst = rows.reversed.toList();

    // Reversed so the list starts, and stays, at the newest message.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: ManoSpacing.md,
        vertical: ManoSpacing.sm,
      ),
      itemCount: newestFirst.length,
      itemBuilder: (context, index) => newestFirst[index],
    );
  }

  Widget _row(BuildContext context, ChatThreadItem item) => switch (item) {
    ConfirmedChatItem() => ManoChatBubble(
      text: item.body,
      timeLabel: ManoFormat.time(item.sentAt),
      mine: item.fromMe,
    ),
    OutgoingChatItem(failed: false) => Opacity(
      key: const Key('chat-item-pending'),
      opacity: 0.55,
      child: ManoChatBubble(
        text: item.body,
        timeLabel: 'Enviando…',
        mine: true,
      ),
    ),
    OutgoingChatItem(failed: true) => _FailedRow(
      body: item.body,
      timeLabel: ManoFormat.time(item.sentAt),
      onTap: () => onRetry(item.localId),
    ),
  };
}

class _FailedRow extends StatelessWidget {
  const _FailedRow({
    required this.body,
    required this.timeLabel,
    required this.onTap,
  });

  final String body;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      key: const Key('chat-item-failed'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Opacity(
            opacity: 0.55,
            child: ManoChatBubble(text: body, timeLabel: timeLabel, mine: true),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: ManoSpacing.xs),
              Text(
                'No se envió. Toca para reintentar.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: ManoSpacing.md),
    child: Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: ManoColors.faint),
      ),
    ),
  );
}
