import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('shows its label and its position', (tester) async {
    await tester.pumpWidget(
      _host(
        ManoToggleRow(
          label: 'Recibir ofertas de mantenimiento',
          value: true,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Recibir ofertas de mantenimiento'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('reports a flip', (tester) async {
    bool? seen;
    await tester.pumpWidget(
      _host(
        ManoToggleRow(
          label: 'Recibir ofertas',
          value: true,
          onChanged: (value) => seen = value,
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(seen, isFalse);
  });

  testWidgets('the whole row is the target, not just the switch', (
    tester,
  ) async {
    // A 40pt switch at the far edge of the screen is a poor thing to ask
    // somebody to hit.
    bool? seen;
    await tester.pumpWidget(
      _host(
        ManoToggleRow(
          label: 'Recibir ofertas',
          value: false,
          onChanged: (value) => seen = value,
        ),
      ),
    );

    await tester.tap(find.text('Recibir ofertas'));
    await tester.pump();

    expect(seen, isTrue);
  });
}
