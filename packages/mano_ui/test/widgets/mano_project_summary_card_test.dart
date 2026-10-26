import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('shows title, subtitle, status and trailing label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ManoProjectSummaryCard(
          title: 'Pintar apartamento de 70 m²',
          subtitle: 'Pintura · hace 5h',
          statusLabel: '3 cotizaciones',
          statusTone: ManoStatusTone.info,
          trailingLabel: r'desde $1.450.000',
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Pintar apartamento de 70 m²'), findsOneWidget);
    expect(find.text('Pintura · hace 5h'), findsOneWidget);
    expect(find.text('3 cotizaciones'), findsOneWidget);
    expect(find.text(r'desde $1.450.000'), findsOneWidget);
  });

  testWidgets('no trailing label and no tap are both fine', (tester) async {
    await tester.pumpWidget(
      _host(
        const ManoProjectSummaryCard(
          title: 'Cambiar tubería del baño',
          subtitle: 'Plomería · hace 1d',
          statusLabel: 'Esperando cotizaciones',
          statusTone: ManoStatusTone.neutral,
        ),
      ),
    );

    expect(find.text('Esperando cotizaciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ManoProjectSummaryCard(
          title: 'Podar árboles',
          subtitle: 'Jardinería',
          statusLabel: 'Cancelado',
          statusTone: ManoStatusTone.neutral,
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('Podar árboles'));

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
          const ManoProjectSummaryCard(
            title: 'Cambiar toda la iluminación a LED',
            subtitle: 'Electricidad · hace 3d',
            statusLabel: 'Elegiste a Profesional',
            statusTone: ManoStatusTone.success,
            trailingLabel: r'$580.000',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
