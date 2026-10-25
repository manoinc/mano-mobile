import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

void main() {
  test('cop groups thousands with dots', () {
    expect(ManoFormat.cop(0), '\$0');
    expect(ManoFormat.cop(950), '\$950');
    expect(ManoFormat.cop(45000), '\$45.000');
    expect(ManoFormat.cop(1250000), '\$1.250.000');
  });

  test('time is 12-hour with a Spanish suffix', () {
    expect(ManoFormat.time(DateTime(2026, 1, 1, 0, 5)), '12:05 a. m.');
    expect(ManoFormat.time(DateTime(2026, 1, 1, 15)), '3:00 p. m.');
  });

  test('dayMonth and dateTime use Spanish month abbreviations', () {
    final at = DateTime(2026, 10, 12, 15);
    expect(ManoFormat.dayMonth(at), '12 oct');
    expect(ManoFormat.dateTime(at), '12 oct, 3:00 p. m.');
  });

  test('weekdayShort is a lowercase Spanish abbreviation', () {
    expect(ManoFormat.weekdayShort(DateTime(2026, 10, 5)), 'lun');
    expect(ManoFormat.weekdayShort(DateTime(2026, 10, 11)), 'dom');
  });

  test('relative is a short elapsed label, never zero', () {
    final now = DateTime(2026, 10, 4, 12);
    String ago(Duration d) => ManoFormat.relative(now.subtract(d), now);
    expect(ago(const Duration(seconds: 30)), '1m');
    expect(ago(const Duration(minutes: 5)), '5m');
    expect(ago(const Duration(minutes: 60)), '1h');
    expect(ago(const Duration(hours: 3)), '3h');
    expect(ago(const Duration(hours: 24)), '1d');
    expect(ago(const Duration(days: 2)), '2d');
  });

  test('relative treats a future timestamp as just now', () {
    final now = DateTime(2026, 10, 4, 12);
    expect(ManoFormat.relative(now.add(const Duration(minutes: 5)), now), '1m');
  });

  test('ago says "hace" before the short elapsed label', () {
    final now = DateTime(2026, 10, 4, 12);
    expect(ManoFormat.ago(now.subtract(const Duration(hours: 5)), now), 'hace 5h');
  });
}
