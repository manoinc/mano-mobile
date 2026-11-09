import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_text_action.dart';

/// An outlined card with one reassurance: icon, title, message, and an optional link.
class ManoInfoCard extends StatelessWidget {
  const ManoInfoCard({
    required this.icon,
    required this.title,
    required this.message,
    this.linkLabel,
    this.onLink,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Shown only with [onLink].
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final link = linkLabel;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ManoRadius.card),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: ManoColors.clay),
            const SizedBox(width: ManoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: ManoSpacing.xs),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (link != null && onLink != null)
                    ManoTextAction(
                      label: link,
                      onPressed: onLink,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
