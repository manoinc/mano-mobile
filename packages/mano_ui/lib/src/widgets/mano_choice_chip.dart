import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A pill to pick (skills, a ticket kind) or, with [onRemove], one to take away.
class ManoChoiceChip extends StatelessWidget {
  const ManoChoiceChip({
    required this.label,
    this.selected = false,
    this.onTap,
    this.onRemove,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Shows a close mark that calls this, for an entry the user added.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = selected ? ManoColors.flame : context.palette.ink;
    final remove = onRemove;

    return Semantics(
      button: onTap != null,
      selected: onTap != null ? selected : null,
      child: Material(
        color: selected
            ? ManoColors.flame.withValues(alpha: 0.12)
            : context.palette.stone,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? ManoColors.flame : Colors.transparent,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: EdgeInsets.only(
                left: ManoSpacing.md,
                right: remove == null ? ManoSpacing.md : ManoSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(color: ink),
                    ),
                  ),
                  if (remove != null)
                    IconButton(
                      onPressed: remove,
                      tooltip: 'Quitar $label',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: context.palette.muted,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
