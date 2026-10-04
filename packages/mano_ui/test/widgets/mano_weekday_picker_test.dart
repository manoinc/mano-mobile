import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('the weekday picker', () {
    testWidgets('draws seven toggles, Monday first', (tester) async {
      await tester.pumpWidget(
        _host(ManoWeekdayPicker(selected: const {}, onToggle: (_) {})),
      );

      for (final letter in ['L', 'M', 'X', 'J', 'V', 'S', 'D']) {
        expect(find.text(letter), findsOneWidget);
      }
    });

    testWidgets('reports the tapped day, 1 for Monday to 7 for Sunday', (
      tester,
    ) async {
      final taps = <int>[];
      await tester.pumpWidget(
        _host(ManoWeekdayPicker(selected: const {}, onToggle: taps.add)),
      );

      await tester.tap(find.text('L'));
      await tester.tap(find.text('D'));

      expect(taps, [1, 7]);
    });

    testWidgets('marks selected days as selected for screen readers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(ManoWeekdayPicker(selected: const {3}, onToggle: (_) {})),
      );

      expect(
        tester.getSemantics(find.text('X')),
        isSemantics(
          label: 'miércoles',
          isButton: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
    });
  });
}
