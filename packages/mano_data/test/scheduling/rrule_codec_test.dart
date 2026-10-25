import 'package:mano_data/src/scheduling/rrule_codec.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('encodeRule', () {
    final cases = <(String, AvailabilityRule, String)>[
      (
        'weekdays mornings',
        const AvailabilityRule(
          weekdays: {1, 2, 3, 4, 5},
          startMinutes: 8 * 60,
          durationMinutes: 240,
        ),
        'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;BYHOUR=8;BYMINUTE=0',
      ),
      (
        'days sorted, half hour start',
        const AvailabilityRule(
          weekdays: {DateTime.sunday, DateTime.wednesday},
          startMinutes: 14 * 60 + 30,
          durationMinutes: 90,
        ),
        'FREQ=WEEKLY;BYDAY=WE,SU;BYHOUR=14;BYMINUTE=30',
      ),
      (
        'midnight saturday',
        const AvailabilityRule(
          weekdays: {DateTime.saturday},
          startMinutes: 0,
          durationMinutes: 30,
        ),
        'FREQ=WEEKLY;BYDAY=SA;BYHOUR=0;BYMINUTE=0',
      ),
    ];
    for (final (name, rule, rrule) in cases) {
      test(name, () {
        final wire = encodeRule(rule);
        expect(wire.rrule, rrule);
        expect(wire.durationMinutes, rule.durationMinutes);
      });
    }
  });

  group('decodeRule', () {
    final cases = <(String, String, int, AvailabilityRule?)>[
      (
        'the gateway example',
        'FREQ=WEEKLY;BYDAY=MO,WE;BYHOUR=8;BYMINUTE=0',
        60,
        const AvailabilityRule(
          id: 'r1',
          weekdays: {1, 3},
          startMinutes: 480,
          durationMinutes: 60,
        ),
      ),
      (
        'key order and case do not matter',
        'byminute=30;byhour=9;byday=SU;freq=weekly',
        30,
        const AvailabilityRule(
          id: 'r1',
          weekdays: {7},
          startMinutes: 570,
          durationMinutes: 30,
        ),
      ),
      (
        'missing BYHOUR and BYMINUTE start at midnight',
        'FREQ=WEEKLY;BYDAY=FR',
        120,
        const AvailabilityRule(
          id: 'r1',
          weekdays: {5},
          startMinutes: 0,
          durationMinutes: 120,
        ),
      ),
      ('not weekly', 'FREQ=DAILY;BYHOUR=8;BYMINUTE=0', 60, null),
      ('no BYDAY', 'FREQ=WEEKLY;BYHOUR=8;BYMINUTE=0', 60, null),
      ('several hours', 'FREQ=WEEKLY;BYDAY=MO;BYHOUR=8,14', 60, null),
      ('several minutes', 'FREQ=WEEKLY;BYDAY=MO;BYMINUTE=0,30', 60, null),
      ('ordinal weekday', 'FREQ=MONTHLY;BYDAY=-1FR', 60, null),
      ('ordinal weekday on weekly', 'FREQ=WEEKLY;BYDAY=1MO', 60, null),
      ('unknown day', 'FREQ=WEEKLY;BYDAY=XX', 60, null),
      ('interval', 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO', 60, null),
      ('count', 'FREQ=WEEKLY;COUNT=3;BYDAY=MO', 60, null),
      ('hour out of range', 'FREQ=WEEKLY;BYDAY=MO;BYHOUR=24', 60, null),
      ('runs past midnight', 'FREQ=WEEKLY;BYDAY=MO;BYHOUR=23', 120, null),
      ('off the 30-minute grid', 'FREQ=WEEKLY;BYDAY=MO;BYHOUR=8', 45, null),
      ('garbage', 'not an rrule', 60, null),
    ];
    for (final (name, rrule, minutes, expected) in cases) {
      test(name, () {
        expect(
          decodeRule(id: 'r1', rrule: rrule, durationMinutes: minutes),
          expected,
        );
      });
    }
  });

  test('a rule survives the round trip', () {
    const rule = AvailabilityRule(
      id: 'r9',
      weekdays: {2, 4, 6},
      startMinutes: 7 * 60 + 30,
      durationMinutes: 300,
    );
    final wire = encodeRule(rule);
    expect(
      decodeRule(
        id: 'r9',
        rrule: wire.rrule,
        durationMinutes: wire.durationMinutes,
      ),
      rule,
    );
  });
}
