import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('the search pill', () {
    testWidgets('shows the default hint when none is given', (tester) async {
      await tester.pumpWidget(_host(ManoSearchPill(onTap: () {})));

      expect(find.text('¿Qué necesitas hoy?'), findsOneWidget);
    });

    testWidgets('shows a custom hint when given', (tester) async {
      await tester.pumpWidget(
        _host(ManoSearchPill(onTap: () {}, hintText: 'Busca un servicio')),
      );

      expect(find.text('Busca un servicio'), findsOneWidget);
      expect(find.text('¿Qué necesitas hoy?'), findsNothing);
    });

    testWidgets('fires onTap once when tapped anywhere on the pill', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(_host(ManoSearchPill(onTap: () => taps++)));

      await tester.tap(find.byType(ManoSearchPill));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
