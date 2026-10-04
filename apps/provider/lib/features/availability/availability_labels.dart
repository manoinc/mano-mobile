import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

// 2024-01-01 was a Monday, so day d of the week is January d.
String _weekday(int day) => ManoFormat.weekdayShort(DateTime(2024, 1, day));

/// "lun – vie", "sáb, dom", or "Todos los días".
String weekdaysLabel(Set<int> weekdays) {
  if (weekdays.length == 7) return 'Todos los días';
  final days = weekdays.toList()..sort();
  final parts = <String>[];
  var i = 0;
  while (i < days.length) {
    var j = i;
    while (j + 1 < days.length && days[j + 1] == days[j] + 1) {
      j++;
    }
    if (j - i >= 2) {
      parts.add('${_weekday(days[i])} – ${_weekday(days[j])}');
    } else {
      for (var k = i; k <= j; k++) {
        parts.add(_weekday(days[k]));
      }
    }
    i = j + 1;
  }
  return parts.join(', ');
}

/// Minutes after midnight as "8:00 a. m.".
String minutesLabel(int minutes) =>
    ManoFormat.time(DateTime(2024).add(Duration(minutes: minutes)));

String ruleLabel(AvailabilityRule rule) =>
    '${weekdaysLabel(rule.weekdays)} · ${minutesLabel(rule.startMinutes)} – '
    '${minutesLabel(rule.startMinutes + rule.durationMinutes)}';

/// Blocks end at the midnight after their last day, so the label shows that day.
String blockLabel(CalendarBlock block) {
  final last = block.end.subtract(const Duration(days: 1));
  final sameDay =
      last.year == block.start.year &&
      last.month == block.start.month &&
      last.day == block.start.day;
  final dates = sameDay || !last.isAfter(block.start)
      ? ManoFormat.dayMonth(block.start)
      : '${ManoFormat.dayMonth(block.start)} – ${ManoFormat.dayMonth(last)}';
  final reason = block.reason;
  return reason == null || reason.isEmpty ? dates : '$dates · $reason';
}
