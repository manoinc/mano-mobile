import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child, {bool still = false}) => MaterialApp(
  theme: ManoTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: Scaffold(body: Center(child: child)),
  ),
);

double _reveal(WidgetTester tester) =>
    tester.widget<ManoLoaderFrame>(find.byType(ManoLoaderFrame)).reveal;

void main() {
  testWidgets('announces itself as loading', (tester) async {
    await tester.pumpWidget(_host(const ManoLoader()));

    expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
  });

  testWidgets('draws the m in from nothing and keeps looping', (tester) async {
    await tester.pumpWidget(_host(const ManoLoader()));
    final start = _reveal(tester);

    await tester.pump(ManoLoader.cycle ~/ 2);
    final middle = _reveal(tester);

    await tester.pump(ManoLoader.cycle);
    expect(start, 0);
    expect(middle, greaterThan(start));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('holds a full, still m when motion is reduced', (tester) async {
    await tester.pumpWidget(_host(const ManoLoader(), still: true));

    expect(_reveal(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the small size fits inside a button', (tester) async {
    await tester.pumpWidget(_host(const ManoLoader.small()));

    expect(tester.getSize(find.byType(ManoLoader)).height, 18);
  });
}
