import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/availability/availability_labels.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  group('weekdaysLabel', () {
    test('collapses a run of three or more days into a range', () {
      expect(weekdaysLabel({1, 2, 3, 4, 5}), 'lun – vie');
    });

    test('lists separate and short runs', () {
      expect(weekdaysLabel({6}), 'sáb');
      expect(weekdaysLabel({6, 7}), 'sáb, dom');
      expect(weekdaysLabel({5, 1, 3}), 'lun, mié, vie');
      expect(weekdaysLabel({1, 2, 3, 6}), 'lun – mié, sáb');
    });

    test('says every day for all seven', () {
      expect(weekdaysLabel({1, 2, 3, 4, 5, 6, 7}), 'Todos los días');
    });
  });

  test('minutesLabel reads minutes after midnight as a time', () {
    expect(minutesLabel(8 * 60), '8:00 a. m.');
    expect(minutesLabel(13 * 60 + 30), '1:30 p. m.');
  });

  test('ruleLabel joins days and the time window', () {
    const rule = AvailabilityRule(
      weekdays: {1, 2, 3, 4, 5},
      startMinutes: 8 * 60,
      durationMinutes: 4 * 60,
    );
    expect(ruleLabel(rule), 'lun – vie · 8:00 a. m. – 12:00 p. m.');
  });

  group('blockLabel', () {
    test('shows the last blocked day, not the exclusive end', () {
      final block = CalendarBlock(
        id: 'b',
        start: DateTime(2026, 10, 12),
        end: DateTime(2026, 10, 15),
        reason: 'Vacaciones',
      );
      expect(blockLabel(block), '12 oct – 14 oct · Vacaciones');
    });

    test('a single day without a reason', () {
      final block = CalendarBlock(
        id: 'b',
        start: DateTime(2026, 10, 12),
        end: DateTime(2026, 10, 13),
      );
      expect(blockLabel(block), '12 oct');
    });
  });

  group('blockedDaysOf', () {
    test('lists every day a block covers, the end instant excluded', () {
      final days = blockedDaysOf([
        CalendarBlock(
          id: 'b',
          start: DateTime(2026, 10, 12),
          end: DateTime(2026, 10, 15),
        ),
      ]);
      expect(days, {
        DateTime(2026, 10, 12),
        DateTime(2026, 10, 13),
        DateTime(2026, 10, 14),
      });
    });
  });
}
