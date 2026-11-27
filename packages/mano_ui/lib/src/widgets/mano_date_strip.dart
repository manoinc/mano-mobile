import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';

/// A horizontal row of day pills for picking a date.
class ManoDateStrip extends StatelessWidget {
  const ManoDateStrip({
    required this.days,
    required this.selected,
    required this.weekdayLabel,
    required this.onSelected,
    this.isEnabled,
    super.key,
  });

  final List<DateTime> days;
  final DateTime? selected;

  /// Turns a day into its short weekday name, e.g. "lun".
  final String Function(DateTime day) weekdayLabel;
  final ValueChanged<DateTime> onSelected;
  final bool Function(DateTime day)? isEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: ManoSpacing.sm),
        itemBuilder: (context, index) {
          final day = days[index];
          final enabled = isEnabled?.call(day) ?? true;
          return _DayPill(
            weekday: weekdayLabel(day),
            day: '${day.day}',
            selected: selected != null && DateUtils.isSameDay(day, selected),
            enabled: enabled,
            onTap: enabled ? () => onSelected(day) : null,
          );
        },
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.weekday,
    required this.day,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String weekday;
  final String day;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected
        ? context.palette.paper
        : enabled
        ? Theme.of(context).colorScheme.onSurface
        : context.palette.faint;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ManoMotion.quick,
        curve: ManoMotion.entrance,
        width: 52,
        decoration: BoxDecoration(
          color: selected ? context.palette.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(ManoRadius.card),
          border: Border.all(
            color: selected ? context.palette.ink : context.palette.stone,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekday,
              style: textTheme.labelSmall?.copyWith(color: foreground),
            ),
            const SizedBox(height: ManoSpacing.xs),
            Text(
              day,
              style: textTheme.titleMedium?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
