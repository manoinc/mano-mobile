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
}
