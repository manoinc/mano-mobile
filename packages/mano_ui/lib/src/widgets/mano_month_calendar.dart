import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';

/// A month grid, Monday first: a flame disc on the selected day, a dot under days with events.
class ManoMonthCalendar extends StatelessWidget {
  const ManoMonthCalendar({
    required this.month,
    required this.selected,
    required this.markedDays,
    required this.onSelect,
    required this.onMonthChanged,
    this.blockedDays = const {},
    super.key,
  });

  /// Any date within the month shown.
  final DateTime month;
  final DateTime selected;

  /// Days that get a dot; the time of day is ignored.
  final Set<DateTime> markedDays;

  /// Days the owner is unavailable; drawn struck through.
  final Set<DateTime> blockedDays;
  final ValueChanged<DateTime> onSelect;

  /// Receives the first of the previous or next month.
  final ValueChanged<DateTime> onMonthChanged;

  static const _initials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final length = DateUtils.getDaysInMonth(month.year, month.month);
    final lead = first.weekday - 1;
    final marked = {for (final d in markedDays) _dateOnly(d)};
    final blocked = {for (final d in blockedDays) _dateOnly(d)};
    final rows = ((lead + length) / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          title: '${_months[month.month - 1]} ${month.year}',
          onPrevious: () =>
              onMonthChanged(DateTime(month.year, month.month - 1)),
          onNext: () => onMonthChanged(DateTime(month.year, month.month + 1)),
        ),
        const SizedBox(height: ManoSpacing.sm),
        Row(
          children: [
            for (final letter in _initials)
              Expanded(
                child: Center(
                  child: Text(
                    letter,
                    key: const Key('mano-calendar-weekday'),
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: context.palette.faint),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: ManoSpacing.xs),
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _cell(
                    row * 7 + col - lead + 1,
                    length,
                    marked,
                    blocked,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(
    int day,
    int length,
    Set<DateTime> marked,
    Set<DateTime> blocked,
  ) {
    if (day < 1 || day > length) return const SizedBox(height: _Day.height);
    final date = DateTime(month.year, month.month, day);
    return _Day(
      date: date,
      selected: _dateOnly(selected) == date,
      marked: marked.contains(date),
      blocked: blocked.contains(date),
      onTap: () => onSelect(date),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton(
          onPressed: onPrevious,
          tooltip: 'Mes anterior',
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: 'Mes siguiente',
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.date,
    required this.selected,
    required this.marked,
    required this.blocked,
    required this.onTap,
  });

  static const double height = 52;
  static const double _disc = 36;
  static const double _gap = 2;
  static const double _dot = 4;

  final DateTime date;
  final bool selected;
  final bool marked;
  final bool blocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    return Semantics(
      button: true,
      selected: selected,
      label: '${date.day}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        key: Key('mano-calendar-day-$key'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: ManoMotion.quick,
                curve: ManoMotion.entrance,
                width: _disc,
                height: _disc,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? ManoColors.flame : null,
                ),
                child: Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected
                        ? Colors.white
                        : blocked
                        ? context.palette.faint
                        : context.palette.ink,
                    decoration: blocked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(height: _gap),
              SizedBox(
                height: _dot,
                child: marked
                    ? DecoratedBox(
                        key: const Key('mano-calendar-dot'),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.palette.clay,
                        ),
                        child: const SizedBox.square(dimension: _dot),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
