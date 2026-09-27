import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

List<Color?> _segments(WidgetTester tester) => tester
    .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
    .map((c) => (c.decoration! as BoxDecoration).color)
    .toList();

void main() {
  testWidgets('draws one line per slide', (tester) async {
    await tester.pumpWidget(_host(const ManoPageIndicator(count: 3, index: 0)));

    expect(_segments(tester).length, 3);
  });

  testWidgets('only the current line is solid', (tester) async {
    await tester.pumpWidget(_host(const ManoPageIndicator(count: 3, index: 1)));
    await tester.pumpAndSettle();

    final colors = _segments(tester);
    final theme = ManoTheme.light();

    expect(colors[1], theme.colorScheme.onSurface);
    expect(colors[0], theme.colorScheme.outlineVariant);
    expect(colors[2], theme.colorScheme.outlineVariant);
  });

  testWidgets('moves the solid line when the slide changes', (tester) async {
    await tester.pumpWidget(_host(const ManoPageIndicator(count: 3, index: 0)));
    await tester.pumpAndSettle();
    expect(_segments(tester)[0], ManoTheme.light().colorScheme.onSurface);

    await tester.pumpWidget(_host(const ManoPageIndicator(count: 3, index: 2)));
    await tester.pumpAndSettle();
    expect(_segments(tester)[2], ManoTheme.light().colorScheme.onSurface);
  });

  testWidgets('is announced as a position rather than read out as lines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const ManoPageIndicator(count: 3, index: 1)));

    expect(find.bySemanticsLabel('Paso 2 de 3'), findsOneWidget);
    handle.dispose();
  });
}
