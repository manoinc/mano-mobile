import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_press_scale.dart';

/// One mark-only way in; [label] is read aloud and shown on long press.
@immutable
class ManoBrandPill {
  const ManoBrandPill({
    required this.mark,
    required this.label,
    required this.onPressed,
  });

  /// The provider's mark, sized by the caller; app assets, never shipped here.
  final Widget mark;
  final String label;

  /// `null` disables the pill.
  final VoidCallback? onPressed;
}

/// Equal-width outlined pills holding only brand marks, Wise's "Or log in with" row.
class ManoBrandPillRow extends StatelessWidget {
  const ManoBrandPillRow({required this.pills, super.key});

  final List<ManoBrandPill> pills;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (final (i, pill) in pills.indexed) ...[
          if (i > 0) const SizedBox(width: ManoSpacing.sm),
          Expanded(
            child: Tooltip(
              message: pill.label,
              child: ManoPressScale(
                enabled: pill.onPressed != null,
                child: OutlinedButton(
                  onPressed: pill.onPressed,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: const StadiumBorder(),
                    backgroundColor: scheme.surface,
                    foregroundColor: scheme.onSurface,
                    side: BorderSide(color: scheme.outline),
                  ),
                  child: Semantics(
                    label: pill.label,
                    child: ExcludeSemantics(child: pill.mark),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
