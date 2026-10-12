import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_text_action.dart';

/// A connected-service row: mark, name and status, one action, and an optional overflow.
class ManoIntegrationRow extends StatelessWidget {
  const ManoIntegrationRow({
    required this.leading,
    required this.title,
    required this.status,
    required this.actionLabel,
    required this.onAction,
    this.onMore,
    super.key,
  });

  /// The service's mark; a third-party logo is an app asset, so it arrives as a widget.
  final Widget leading;
  final String title;

  /// Pre-formatted, e.g. "No conectado".
  final String status;
  final String actionLabel;

  /// Null disables the action.
  final VoidCallback? onAction;

  /// When given, a trailing overflow button appears.
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        leading,
        const SizedBox(width: ManoSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall),
              Text(
                status,
                style: textTheme.bodySmall?.copyWith(color: ManoColors.faint),
              ),
            ],
          ),
        ),
        Flexible(
          child: ManoTextAction(label: actionLabel, onPressed: onAction),
        ),
        if (onMore != null)
          IconButton(
            onPressed: onMore,
            tooltip: 'Más opciones',
            icon: const Icon(Icons.more_horiz, color: ManoColors.muted),
          ),
      ],
    );
  }
}
