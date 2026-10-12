import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone-sized surface, so the day's cards sit below the calendar on screen.
void useTallPhone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1200, 2600)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

/// The calendar cell for [day].
Finder agendaDay(DateTime day) => find.byKey(
  Key(
    'mano-calendar-day-${day.year}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}',
  ),
);

/// Taps [day] on the agenda calendar, paging to its month first if needed.
Future<void> selectAgendaDay(WidgetTester tester, DateTime day) async {
  final now = DateTime.now();
  final months = (day.year - now.year) * 12 + day.month - now.month;
  for (var i = 0; i < months.abs(); i++) {
    await tester.tap(
      find.byTooltip(months > 0 ? 'Mes siguiente' : 'Mes anterior'),
    );
    await tester.pumpAndSettle();
  }
  await tester.tap(agendaDay(day));
  await tester.pumpAndSettle();
}
