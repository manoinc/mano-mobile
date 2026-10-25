import 'package:mano_domain/mano_domain.dart';

/// An [AvailabilityRule] as the gateway stores it.
typedef RRuleWire = ({String rrule, int durationMinutes});

// RFC 5545 day codes, indexed by DateTime.monday (1) through DateTime.sunday (7).
const _days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// Weekly RRULE with one BYHOUR and BYMINUTE, in the provider's local time.
RRuleWire encodeRule(AvailabilityRule rule) {
  final days = (rule.weekdays.toList()..sort()).map((d) => _days[d - 1]);
  return (
    rrule:
        'FREQ=WEEKLY;BYDAY=${days.join(',')};'
        'BYHOUR=${rule.startMinutes ~/ 60};BYMINUTE=${rule.startMinutes % 60}',
    durationMinutes: rule.durationMinutes,
  );
}

/// Null for any recurrence a weekly window cannot represent.
AvailabilityRule? decodeRule({
  required String? id,
  required String rrule,
  required int durationMinutes,
}) {
  final parts = <String, String>{};
  for (final part in rrule.toUpperCase().split(';')) {
    final pair = part.split('=');
    if (pair.length != 2 || parts.containsKey(pair.first)) return null;
    parts[pair.first] = pair.last;
  }
  const known = {'FREQ', 'BYDAY', 'BYHOUR', 'BYMINUTE'};
  if (parts['FREQ'] != 'WEEKLY' || !parts.keys.every(known.contains)) {
    return null;
  }

  final weekdays = <int>{};
  for (final code in (parts['BYDAY'] ?? '').split(',')) {
    final index = _days.indexOf(code);
    if (index < 0) return null;
    weekdays.add(index + 1);
  }
  final hour = _single(parts['BYHOUR'], max: 23);
  final minute = _single(parts['BYMINUTE'], max: 59);
  if (hour == null || minute == null) return null;

  final rule = AvailabilityRule(
    id: id,
    weekdays: weekdays,
    startMinutes: hour * 60 + minute,
    durationMinutes: durationMinutes,
  );
  return rule.isValid ? rule : null;
}

// Absent means midnight, as the scheduler expands from DTSTART at 00:00.
int? _single(String? value, {required int max}) {
  if (value == null) return 0;
  final n = int.tryParse(value);
  return n != null && n >= 0 && n <= max ? n : null;
}
