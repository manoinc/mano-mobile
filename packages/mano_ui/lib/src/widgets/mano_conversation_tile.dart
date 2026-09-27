import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_avatar.dart';

/// A single conversation, as shown in the Inbox tab's list.
///
/// Takes only strings, booleans and a callback -- no `Conversation` entity
/// and no date formatting. `timestampLabel` arrives pre-formatted, e.g. "5m",
/// because turning a `DateTime` into that needs a locale, which is a
/// screen-level concern.
class ManoConversationTile extends StatelessWidget {
  const ManoConversationTile({
    required this.avatarUrl,
    required this.online,
    required this.verified,
    required this.name,
    required this.snippet,
    required this.timestampLabel,
    required this.unreadCount,
    required this.onTap,
    super.key,
  });

  final String avatarUrl;
  final bool online;
  final bool verified;
  final String name;
  final String snippet;

  /// Pre-formatted, e.g. "5m".
  final String timestampLabel;

  /// `0` hides the unread badge entirely -- a badge that reads "0" would say
  /// less than no badge at all.
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ManoSpacing.md,
          vertical: ManoSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ManoAvatar(photoUrl: avatarUrl, size: 48, online: online),
            const SizedBox(width: ManoSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall,
                        ),
                      ),
                      if (verified) ...[
                        const SizedBox(width: ManoSpacing.xs),
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: ManoColors.clay,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    snippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: ManoSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timestampLabel,
                  style: textTheme.labelSmall?.copyWith(color: ManoColors.faint),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(height: ManoSpacing.xs),
                  Container(
                    key: const Key('mano-conversation-tile-unread-badge'),
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: ManoSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: ManoColors.flame,
                      borderRadius: BorderRadius.all(Radius.circular(ManoRadius.pill)),
                    ),
                    child: Text(
                      '$unreadCount',
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
