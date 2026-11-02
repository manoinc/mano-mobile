import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';

const _words = ['Muy malo', 'Malo', 'Regular', 'Bueno', 'Excelente'];

/// Five large stars to tap a rating, with the word for it underneath.
class ManoStarInput extends StatelessWidget {
  const ManoStarInput({
    required this.value,
    required this.onChanged,
    this.size = 44,
    super.key,
  });

  /// Zero until a star is chosen.
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var n = 1; n <= 5; n++)
              Semantics(
                label: n == 1 ? '1 estrella' : '$n estrellas',
                button: true,
                selected: n == value,
                onTap: () => onChanged(n),
                child: ExcludeSemantics(
                  child: InkResponse(
                    onTap: () => onChanged(n),
                    radius: size * 0.6,
                    child: Padding(
                      padding: const EdgeInsets.only(right: ManoSpacing.xs),
                      child: AnimatedScale(
                        scale: n == value ? 1.12 : 1,
                        duration: ManoMotion.normal,
                        curve: ManoMotion.entrance,
                        child: Icon(
                          n <= value
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: size,
                          color: n <= value
                              ? ManoColors.clay
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: ManoSpacing.sm),
        AnimatedSwitcher(
          duration: ManoMotion.normal,
          child: Text(
            value >= 1 && value <= 5 ? _words[value - 1] : '',
            key: ValueKey(value),
            style: theme.textTheme.titleSmall?.copyWith(
              color: ManoColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}
