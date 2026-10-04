import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('ManoStatusChip', () {
    testWidgets('shows its label in every tone', (tester) async {
      for (final tone in ManoStatusTone.values) {
        await tester.pumpWidget(
          _host(ManoStatusChip(label: 'Programado', tone: tone)),
        );
        expect(find.text('Programado'), findsOneWidget);
      }
    });
  });

  group('ManoPriceTag', () {
    testWidgets('shows amount and rate suffix', (tester) async {
      await tester.pumpWidget(
        _host(const ManoPriceTag(amountLabel: '\$45.000', rateLabel: '/hora')),
      );
      expect(find.text('\$45.000'), findsOneWidget);
      expect(find.text('/hora'), findsOneWidget);
    });
  });

  group('ManoDateStrip', () {
    final days = List.generate(7, (i) => DateTime(2026, 10, 5 + i));

    testWidgets('renders each day and reports the tapped one', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        _host(
          ManoDateStrip(
            days: days,
            selected: days.first,
            weekdayLabel: (d) => 'd${d.weekday}',
            onSelected: (d) => picked = d,
          ),
        ),
      );
      expect(find.text('5'), findsOneWidget);
      expect(find.text('d1'), findsOneWidget);
      await tester.tap(find.text('7'));
      expect(picked, days[2]);
    });

    testWidgets('disabled days cannot be picked', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        _host(
          ManoDateStrip(
            days: days,
            selected: days.first,
            weekdayLabel: (d) => '',
            isEnabled: (d) => d.day != 6,
            onSelected: (d) => picked = d,
          ),
        ),
      );
      await tester.tap(find.text('6'));
      expect(picked, isNull);
    });
  });

  group('ManoSlotGrid', () {
    testWidgets('taps enabled slots only', (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(
        _host(
          ManoSlotGrid(
            slots: const [
              ManoSlot(label: '8:00 a. m.'),
              ManoSlot(label: '9:00 a. m.', enabled: false),
            ],
            selectedIndex: null,
            onSelected: tapped.add,
          ),
        ),
      );
      await tester.tap(find.text('8:00 a. m.'));
      await tester.tap(find.text('9:00 a. m.'));
      expect(tapped, [0]);
    });

    testWidgets('shows the empty label when there are no slots', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ManoSlotGrid(
            slots: const [],
            selectedIndex: null,
            onSelected: (_) {},
            emptyLabel: 'Sin horarios',
          ),
        ),
      );
      expect(find.text('Sin horarios'), findsOneWidget);
    });
  });

  group('ManoChatBubble', () {
    testWidgets('mine aligns right, theirs left', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              ManoChatBubble(text: 'mío', timeLabel: '9:00', mine: true),
              ManoChatBubble(text: 'suyo', timeLabel: '9:01', mine: false),
            ],
          ),
        ),
      );
      Align alignOf(String text) => tester.widget<Align>(
        find.ancestor(of: find.text(text), matching: find.byType(Align)).first,
      );
      expect(alignOf('mío').alignment, Alignment.centerRight);
      expect(alignOf('suyo').alignment, Alignment.centerLeft);
      expect(find.text('9:00'), findsOneWidget);
    });
  });

  group('ManoMessageComposer', () {
    testWidgets('sends trimmed text and clears; ignores blanks', (
      tester,
    ) async {
      final sent = <String>[];
      await tester.pumpWidget(
        _host(ManoMessageComposer(hintText: 'Escribe…', onSend: sent.add)),
      );
      await tester.tap(find.byKey(const Key('mano-composer-send')));
      expect(sent, isEmpty);

      await tester.enterText(find.byType(TextField), '  hola  ');
      await tester.tap(find.byKey(const Key('mano-composer-send')));
      await tester.pump();
      expect(sent, ['hola']);
      expect(find.text('  hola  '), findsNothing);
    });
  });
}
