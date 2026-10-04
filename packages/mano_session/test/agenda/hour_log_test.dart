import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  final start = DateTime(2026, 10, 4, 8);

  group('loggedHoursSince', () {
    test('rounds the elapsed time to the nearest half hour', () {
      expect(loggedHoursSince(start, DateTime(2026, 10, 4, 10, 10)), 2.0);
      expect(loggedHoursSince(start, DateTime(2026, 10, 4, 10, 20)), 2.5);
      expect(loggedHoursSince(start, DateTime(2026, 10, 4, 10, 45)), 3.0);
    });

    test('never goes below half an hour', () {
      expect(loggedHoursSince(start, DateTime(2026, 10, 4, 8, 5)), 0.5);
      expect(loggedHoursSince(start, DateTime(2026, 10, 3, 8)), 0.5);
    });
  });

  group('stepping', () {
    test('adds half an hour', () => expect(addHalfHour(2), 2.5));

    test('removes half an hour down to the minimum', () {
      expect(removeHalfHour(2), 1.5);
      expect(removeHalfHour(0.5), 0.5);
    });

    test('canRemoveHalfHour stops at the minimum', () {
      expect(canRemoveHalfHour(1), isTrue);
      expect(canRemoveHalfHour(0.5), isFalse);
    });
  });

  test('hourlyTotalCop multiplies hours by the rate', () {
    expect(hourlyTotalCop(2.5, 45000), 112500);
    expect(hourlyTotalCop(0.5, 38001), 19001);
  });
}
