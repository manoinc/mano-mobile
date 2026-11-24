import 'dart:async';

import 'package:flutter/material.dart';

import '../format/mano_format.dart';
import '../theme/mano_theme.dart';
import 'mano_chat_bubble.dart';
import 'mano_chat_thread.dart';
import 'mano_message_composer.dart';

/// A support ticket's conversation: pull to refresh, then the composer or a note.
///
/// [entries] run oldest first; the ones not [ManoChatEntry.mine] are staff and
/// carry [staffLabel]. A null [onSend] swaps the composer for [closedNote].
class ManoSupportThread extends StatelessWidget {
  const ManoSupportThread({
    required this.entries,
    required this.staffLabel,
    required this.hintText,
    required this.closedNote,
    required this.onRefresh,
    required this.onSend,
    super.key,
  });

  final List<ManoChatEntry> entries;
  final String staffLabel;
  final String hintText;
  final String closedNote;
  final Future<void> Function() onRefresh;

  /// Gets the trimmed body; true clears the field. Null when the ticket is closed.
  final FutureOr<bool> Function(String body)? onSend;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: ManoColors.faint);
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(ManoSpacing.md),
              itemCount: entries.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: ManoSpacing.sm),
              itemBuilder: (context, i) {
                final entry = entries[i];
                return Column(
                  crossAxisAlignment: entry.mine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!entry.mine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: ManoSpacing.xs),
                        child: Text(staffLabel, style: labelStyle),
                      ),
                    ManoChatBubble(
                      text: entry.text,
                      mine: entry.mine,
                      timeLabel: ManoFormat.time(entry.sentAt),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        if (onSend case final send?)
          ManoMessageComposer(hintText: hintText, onSend: send)
        else
          Padding(
            padding: const EdgeInsets.all(ManoSpacing.md),
            child: Text(
              closedNote,
              textAlign: TextAlign.center,
              style: labelStyle,
            ),
          ),
      ],
    );
  }
}
