import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A small quiet pill after a label, e.g. "Predeterminado".
class TagPill extends StatelessWidget {
  const TagPill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(ManoRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ManoSpacing.sm,
          vertical: 2,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.palette.muted,
          ),
        ),
      ),
    );
  }
}
