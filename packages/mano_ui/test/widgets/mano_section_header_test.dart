import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('shows the title with a chevron when tappable', (tester) async {
    await tester.pumpWidget(
      _host(ManoSectionHeader(title: 'Mejor calificados', onTap: () {})),
    );

    expect(find.text('Mejor calificados'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('tapping the title calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(ManoSectionHeader(title: 'Limpieza', onTap: () => taps++)),
    );

    await tester.tap(find.text('Limpieza'));

    expect(taps, 1);
  });

  testWidgets('without onTap there is no chevron', (tester) async {
    await tester.pumpWidget(_host(const ManoSectionHeader(title: 'Limpieza')));

    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('a long title at large text scale does not overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _host(
          SizedBox(
            width: 200,
            child: ManoSectionHeader(
              title: 'Proyectos pequeños para esta semana en tu barrio',
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
