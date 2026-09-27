import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// One opt-in, stated plainly, on a quiet raised ground.
///
/// The whole row is the target: a switch alone is a small thing to ask
/// somebody to hit at the edge of a sheet.
class ManoToggleRow extends StatelessWidget {
  const ManoToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(ManoRadius.card),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(ManoRadius.card),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ManoSpacing.md,
            ManoSpacing.sm,
            ManoSpacing.sm,
            ManoSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: theme.textTheme.bodyMedium),
              ),
              const SizedBox(width: ManoSpacing.sm),
              ExcludeSemantics(
                child: Switch(value: value, onChanged: onChanged),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
