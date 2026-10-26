import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('shows the project, its age, the budget and the cost', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ManoLeadCard(
          title: 'Pintar apartamento de 70 m²',
          categoryLabel: 'Pintura',
          ageLabel: 'hace 5h',
          budgetLabel: r'Presupuesto $1.800.000',
          costLabel: 'Gratis',
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Pintar apartamento de 70 m²'), findsOneWidget);
    expect(find.text('Pintura · hace 5h'), findsOneWidget);
    expect(find.text(r'Presupuesto $1.800.000'), findsOneWidget);
    expect(find.text('Gratis'), findsOneWidget);
  });

  testWidgets('fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ManoLeadCard(
          title: 'Instalar calentador',
          categoryLabel: 'Plomería',
          ageLabel: 'hace 1d',
          budgetLabel: 'Sin presupuesto',
          costLabel: 'Gratis',
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('Instalar calentador'));

    expect(taps, 1);
  });

  testWidgets('fits 360 dp at 2x text', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _host(
          ManoLeadCard(
            title: 'Diseño de jardín vertical en el balcón del apartamento',
            categoryLabel: 'Jardinería',
            ageLabel: 'hace 4d',
            budgetLabel: r'Presupuesto $2.500.000',
            costLabel: 'Gratis',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
