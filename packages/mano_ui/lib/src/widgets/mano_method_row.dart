import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'tag_pill.dart';

/// A saved payment method: mark, name and detail, with one small outlined action.
class ManoMethodRow extends StatelessWidget {
  const ManoMethodRow({
    required this.leading,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.detail,
    this.tag,
    super.key,
  });

  /// The method's mark; a third-party logo is an app asset.
  final Widget leading;
  final String title;
  final String? detail;

  /// A small pill after the title, e.g. "Predeterminado".
  final String? tag;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ManoSpacing.md),
      child: Row(
        children: [
          IconTheme.merge(
            data: IconThemeData(color: scheme.onSurface, size: 28),
            child: leading,
          ),
          const SizedBox(width: ManoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: ManoSpacing.sm,
                  runSpacing: ManoSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (tag case final tag?) TagPill(tag),
                  ],
                ),
                if (detail case final detail?)
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.palette.faint,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: ManoSpacing.sm),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: ManoSpacing.md),
              shape: const StadiumBorder(),
              foregroundColor: scheme.onSurface,
              textStyle: theme.textTheme.labelLarge,
              side: BorderSide(color: scheme.outline),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
