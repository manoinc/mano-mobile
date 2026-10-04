import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/agenda/agenda_labels.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

void main() {
  final today = DateTime(2026, 10, 4, 15);

  test('dayLabel names today and tomorrow, else weekday and date', () {
    expect(dayLabel(DateTime(2026, 10, 4), today), 'Hoy');
    expect(dayLabel(DateTime(2026, 10, 5), today), 'Mañana');
    final later = DateTime(2026, 10, 8);
    expect(
      dayLabel(later, today),
      '${ManoFormat.weekdayShort(later)} ${ManoFormat.dayMonth(later)}',
    );
  });

  test('hoursLabel uses a decimal comma and drops whole decimals', () {
    expect(hoursLabel(2.5), '2,5 h');
    expect(hoursLabel(3), '3 h');
  });

  test('shortPrice adds /hora for hourly jobs', () {
    expect(shortPrice(45000, RateType.hourly), r'$45.000/hora');
    expect(shortPrice(120000, RateType.fixed), r'$120.000');
  });
}
