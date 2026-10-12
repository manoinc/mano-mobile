import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

final _start = find.byKey(const Key('mano-time-wheel-start'));
final _end = find.byKey(const Key('mano-time-wheel-end'));

void main() {
  group('the time range picker', () {
    testWidgets('labels both wheels and shows the current times', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ManoTimeRangePicker(
            startMinutes: 8 * 60,
            endMinutes: 12 * 60,
            onChanged: (_, _) {},
          ),
        ),
      );

      expect(find.text('Desde'), findsOneWidget);
      expect(find.text('Hasta'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
    });

    testWidgets('keeps its fixed height', (tester) async {
      await tester.pumpWidget(
        _host(
          ManoTimeRangePicker(
            startMinutes: 0,
            endMinutes: 24 * 60,
            onChanged: (_, _) {},
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(ManoTimeRangePicker)).height,
        ManoTimeRangePicker.height,
      );
    });

    testWidgets('scrolling the start wheel reports a 30-minute step', (
      tester,
    ) async {
      ({int start, int end})? got;
      await tester.pumpWidget(
        _host(
          ManoTimeRangePicker(
            startMinutes: 8 * 60,
            endMinutes: 12 * 60,
            onChanged: (s, e) => got = (start: s, end: e),
          ),
        ),
      );

      await tester.drag(_start, const Offset(0, -ManoTimeRangePicker.itemExtent * 2));
      await tester.pumpAndSettle();

      expect(got, (start: 9 * 60, end: 12 * 60));
    });

    testWidgets('scrolling the end wheel moves only the end', (tester) async {
      ({int start, int end})? got;
      await tester.pumpWidget(
        _host(
          ManoTimeRangePicker(
            startMinutes: 8 * 60,
            endMinutes: 12 * 60,
            onChanged: (s, e) => got = (start: s, end: e),
          ),
        ),
      );

      await tester.drag(_end, const Offset(0, ManoTimeRangePicker.itemExtent));
      await tester.pumpAndSettle();

      expect(got, (start: 8 * 60, end: 11 * 60 + 30));
    });

    testWidgets('uses a custom label when given', (tester) async {
      await tester.pumpWidget(
        _host(
          ManoTimeRangePicker(
            startMinutes: 8 * 60,
            endMinutes: 12 * 60,
            labelFor: (m) => '$m min',
            onChanged: (_, _) {},
          ),
        ),
      );

      expect(find.text('480 min'), findsOneWidget);
    });
  });
}
