import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';

/// Seven round toggles, L to D; days are 1 (Monday) to 7 (Sunday).
class ManoWeekdayPicker extends StatelessWidget {
  const ManoWeekdayPicker({
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  static const _letters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _names = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var day = 1; day <= 7; day++)
          _DayToggle(
            letter: _letters[day - 1],
            name: _names[day - 1],
            selected: selected.contains(day),
            onTap: () => onToggle(day),
          ),
      ],
    );
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.letter,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      label: name,
      button: true,
      selected: selected,
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: AnimatedContainer(
          duration: ManoMotion.quick,
          curve: ManoMotion.entrance,
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? scheme.onSurface : scheme.surfaceContainerHighest,
          ),
          child: Text(
            letter,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? scheme.surface : ManoColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
