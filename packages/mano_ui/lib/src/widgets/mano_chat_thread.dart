import 'package:flutter/material.dart';

import '../format/mano_format.dart';
import '../theme/mano_theme.dart';
import 'mano_chat_bubble.dart';
import 'mano_image_viewer.dart';
import 'mano_photo_picker_grid.dart';
import 'mano_receipt_mark.dart';

/// Delivery state of a [ManoChatEntry].
enum ManoChatEntryStatus { sent, pending, failed }

/// One message as the thread draws it; [id] is what `onRetry` receives.
class ManoChatEntry {
  const ManoChatEntry({
    required this.id,
    required this.text,
    required this.sentAt,
    this.mine = false,
    this.status = ManoChatEntryStatus.sent,
    this.receipt = ManoReceipt.sent,
    this.photos = const [],
  });

  final String id;
  final String text;
  final DateTime sentAt;
  final bool mine;
  final ManoChatEntryStatus status;

  /// How far my confirmed message got; ignored on theirs.
  final ManoReceipt receipt;

  /// Drawn above [text]; an empty [text] shows the photos alone.
  final List<ImageProvider> photos;

  List<Object> get heroTags => [
    for (var i = 0; i < photos.length; i++) ManoImageViewer.heroTagFor(id, i),
  ];
}

/// A chat history, oldest first in [entries], pinned to the newest message.
///
/// Confirmed messages from one sender within two minutes read as one group.
/// Tapping a photo opens it in [ManoImageViewer].
class ManoChatThread extends StatelessWidget {
  const ManoChatThread({
    required this.entries,
    required this.emptyMessage,
    required this.onRetry,
    super.key,
  });

  /// The longest silence that still keeps messages in one group.
  static const groupWindow = Duration(minutes: 2);

  final List<ManoChatEntry> entries;
  final String emptyMessage;
  final ValueChanged<String> onRetry;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _joined(ManoChatEntry a, ManoChatEntry b) =>
      a.status == ManoChatEntryStatus.sent &&
      b.status == ManoChatEntryStatus.sent &&
      a.mine == b.mine &&
      _sameDay(a.sentAt, b.sentAt) &&
      b.sentAt.difference(a.sentAt) <= groupWindow;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return _Empty(message: emptyMessage);

    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final previous = i > 0 ? entries[i - 1] : null;
      final next = i < entries.length - 1 ? entries[i + 1] : null;
      final newDay =
          previous == null || !_sameDay(previous.sentAt, entry.sentAt);
      if (newDay) {
        rows.add(_DaySeparator(label: ManoFormat.dayMonth(entry.sentAt)));
      }
      final joinedPrevious = previous != null && _joined(previous, entry);
      final gap = newDay
          ? 0.0
          : joinedPrevious
          ? ManoSpacing.xs
          : previous.mine != entry.mine
          ? ManoSpacing.md
          : ManoSpacing.sm;
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: gap),
          child: _row(
            context,
            entry,
            isFirst: !joinedPrevious,
            isLast: next == null || !_joined(entry, next),
          ),
        ),
      );
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

  Widget _row(
    BuildContext context,
    ManoChatEntry entry, {
    required bool isFirst,
    required bool isLast,
  }) => switch (entry.status) {
    ManoChatEntryStatus.sent => ManoChatBubble(
      text: entry.text,
      mine: entry.mine,
      timeLabel: isLast ? ManoFormat.time(entry.sentAt) : null,
      receipt: entry.mine && isLast ? entry.receipt : null,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
      photos: entry.photos,
      photoHeroTags: entry.heroTags,
      onPhotoTap: (i) => ManoImageViewer.show(
        context,
        image: entry.photos[i],
        heroTag: entry.heroTags[i],
      ),
    ),
    ManoChatEntryStatus.pending => Opacity(
      key: const Key('chat-item-pending'),
      opacity: entry.photos.isEmpty ? 0.55 : 1,
      child: ManoChatBubble(
        text: entry.text,
        timeLabel: 'Enviando…',
        mine: entry.mine,
        photos: entry.photos,
        photoStatus: ManoPhotoStatus.uploading,
      ),
    ),
    ManoChatEntryStatus.failed => _FailedRow(
      entry: entry,
      onTap: () => onRetry(entry.id),
    ),
  };
}

class _FailedRow extends StatelessWidget {
  const _FailedRow({required this.entry, required this.onTap});

  final ManoChatEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return GestureDetector(
      key: const Key('chat-item-failed'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: entry.mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: 0.55,
            child: ManoChatBubble(
              text: entry.text,
              timeLabel: ManoFormat.time(entry.sentAt),
              mine: entry.mine,
              photos: entry.photos,
              photoStatus: ManoPhotoStatus.failed,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 14, color: error),
              const SizedBox(width: ManoSpacing.xs),
              Text(
                'No se envió. Toca para reintentar.',
                style: theme.textTheme.labelSmall?.copyWith(color: error),
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
            ?.copyWith(color: context.palette.faint),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.chat_bubble_outline_rounded,
          size: 40,
          color: context.palette.faint,
        ),
        const SizedBox(height: ManoSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: context.palette.muted),
        ),
      ],
    ),
  );
}
