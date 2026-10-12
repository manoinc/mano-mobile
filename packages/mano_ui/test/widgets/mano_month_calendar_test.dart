import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: child),
);

Finder _day(int d) => find.byKey(
  Key('mano-calendar-day-2026-10-${d.toString().padLeft(2, '0')}'),
);

ManoMonthCalendar _calendar({
  Set<DateTime> marked = const {},
  DateTime? selected,
  ValueChanged<DateTime>? onSelect,
  ValueChanged<DateTime>? onMonthChanged,
  Set<DateTime> blocked = const {},
}) => ManoMonthCalendar(
  month: DateTime(2026, 10),
  selected: selected ?? DateTime(2026, 10, 15),
  markedDays: marked,
  blockedDays: blocked,
  onSelect: onSelect ?? (_) {},
  onMonthChanged: onMonthChanged ?? (_) {},
);

void main() {
  group('the month calendar', () {
    testWidgets('titles the month and starts the week on Monday', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_calendar()));

      expect(find.text('Octubre 2026'), findsOneWidget);
      final initials = tester
          .widgetList<Text>(find.byKey(const Key('mano-calendar-weekday')))
          .map((t) => t.data)
          .toList();
      expect(initials, ['L', 'M', 'M', 'J', 'V', 'S', 'D']);
      // 1 Oct 2026 is a Thursday: the fourth column.
      final thursday = find.byKey(const Key('mano-calendar-weekday')).at(3);
      expect(tester.getCenter(_day(1)).dx, tester.getCenter(thursday).dx);
      expect(_day(31), findsOneWidget);
    });

    testWidgets('paints the selected day in flame', (tester) async {
      await tester.pumpWidget(
        _host(_calendar(selected: DateTime(2026, 10, 9))),
      );

      Color? fill(int d) {
        final box = tester.widget<DecoratedBox>(
          find.descendant(of: _day(d), matching: find.byType(DecoratedBox)),
        );
        return (box.decoration as BoxDecoration).color;
      }

      expect(fill(9), ManoColors.flame);
      expect(fill(10), isNull);
    });

    testWidgets('marks days with events by a dot', (tester) async {
      await tester.pumpWidget(
        _host(_calendar(marked: {DateTime(2026, 10, 12, 18, 30)})),
      );

      Finder dot(int d) => find.descendant(
        of: _day(d),
        matching: find.byKey(const Key('mano-calendar-dot')),
      );
      expect(dot(12), findsOneWidget);
      expect(dot(13), findsNothing);
    });

    testWidgets('keeps the dot clear of the selected disc', (tester) async {
      await tester.pumpWidget(
        _host(
          _calendar(
            selected: DateTime(2026, 10, 12),
            marked: {DateTime(2026, 10, 12)},
          ),
        ),
      );

      final disc = tester.getRect(
        find.descendant(of: _day(12), matching: find.byType(AnimatedContainer)),
      );
      final dot = tester.getRect(find.byKey(const Key('mano-calendar-dot')));
      expect(dot.top, greaterThan(disc.bottom));
    });

    testWidgets('strikes through blocked days', (tester) async {
      await tester.pumpWidget(
        _host(_calendar(blocked: {DateTime(2026, 10, 20, 9)})),
      );

      TextDecoration? decoration(int d) => tester
          .widget<Text>(
            find.descendant(of: _day(d), matching: find.byType(Text)),
          )
          .style
          ?.decoration;
      expect(decoration(20), TextDecoration.lineThrough);
      expect(decoration(21), isNot(TextDecoration.lineThrough));
    });

    testWidgets('reports taps on a day', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(_host(_calendar(onSelect: (d) => picked = d)));

      await tester.tap(_day(20));
      expect(picked, DateTime(2026, 10, 20));
    });

    testWidgets('steps to the previous and next month', (tester) async {
      final months = <DateTime>[];
      await tester.pumpWidget(_host(_calendar(onMonthChanged: months.add)));

      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.tap(find.byTooltip('Mes siguiente'));

      expect(months, [DateTime(2026, 9), DateTime(2026, 11)]);
    });

    testWidgets('rolls the year over in December', (tester) async {
      final months = <DateTime>[];
      await tester.pumpWidget(
        _host(
          ManoMonthCalendar(
            month: DateTime(2026, 12),
            selected: DateTime(2026, 12, 1),
            markedDays: const {},
            onSelect: (_) {},
            onMonthChanged: months.add,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Mes siguiente'));
      expect(months, [DateTime(2027)]);
    });
  });
}
