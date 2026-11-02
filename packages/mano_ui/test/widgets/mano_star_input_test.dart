import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('tapping a star reports how many stars were chosen', (
    tester,
  ) async {
    int? chosen;
    await tester.pumpWidget(
      _host(ManoStarInput(value: 0, onChanged: (v) => chosen = v)),
    );

    await tester.tap(find.bySemanticsLabel('4 estrellas'));
    expect(chosen, 4);
    await tester.tap(find.bySemanticsLabel('1 estrella'));
    expect(chosen, 1);
  });

  testWidgets('shows the word for the chosen rating, nothing before', (
    tester,
  ) async {
    await tester.pumpWidget(_host(ManoStarInput(value: 0, onChanged: (_) {})));
    expect(find.text('Excelente'), findsNothing);

    await tester.pumpWidget(_host(ManoStarInput(value: 5, onChanged: (_) {})));
    expect(find.text('Excelente'), findsOneWidget);

    await tester.pumpWidget(_host(ManoStarInput(value: 2, onChanged: (_) {})));
    expect(find.text('Malo'), findsOneWidget);
  });

  testWidgets('fills as many stars as the value', (tester) async {
    await tester.pumpWidget(_host(ManoStarInput(value: 3, onChanged: (_) {})));
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(2));
  });

  testWidgets('marks the chosen star selected for screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(ManoStarInput(value: 3, onChanged: (_) {})));
    expect(
      tester.getSemantics(find.bySemanticsLabel('3 estrellas')),
      matchesSemantics(
        label: '3 estrellas',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
