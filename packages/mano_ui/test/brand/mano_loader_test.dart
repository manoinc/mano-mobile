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

ManoLoaderFrame _frame(WidgetTester tester) =>
    tester.widget<ManoLoaderFrame>(find.byType(ManoLoaderFrame));

void main() {
  testWidgets('announces itself as loading', (tester) async {
    await tester.pumpWidget(_host(const ManoLoader()));

    expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
  });

  testWidgets('a cycle ends exactly where it began', (tester) async {
    await tester.pumpWidget(_host(const ManoLoader()));
    final start = _frame(tester);

    await tester.pump(ManoLoader.cycle ~/ 2);
    final middle = _frame(tester);

    await tester.pump(ManoLoader.cycle ~/ 2 - const Duration(milliseconds: 1));
    final end = _frame(tester);

    expect((start.from, start.to), (0.0, 0.0));
    expect((middle.from, middle.to), (0.0, 1.0));
    expect(end.from, closeTo(1, 0.01));
    expect(end.to, 1);
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('both edges only ever travel left to right', (tester) async {
    await tester.pumpWidget(_host(const ManoLoader()));
    var last = _frame(tester);
    for (var i = 0; i < 27; i++) {
      await tester.pump(ManoLoader.cycle ~/ 28);
      final now = _frame(tester);
      expect(now.from, greaterThanOrEqualTo(last.from));
      expect(now.to, greaterThanOrEqualTo(last.to));
      expect(now.to, greaterThanOrEqualTo(now.from));
      last = now;
    }
  });

  testWidgets('holds a full, still m when motion is reduced', (tester) async {
    await tester.pumpWidget(_host(const ManoLoader(), still: true));

    expect((_frame(tester).from, _frame(tester).to), (0.0, 1.0));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the small size fits inside a button', (tester) async {
    await tester.pumpWidget(_host(const ManoLoader.small()));

    expect(tester.getSize(find.byType(ManoLoader)).height, 18);
  });
}
