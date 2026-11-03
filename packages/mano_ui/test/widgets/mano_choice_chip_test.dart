import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('taps and reports its selection to semantics', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ManoChoiceChip(label: 'Plomería', selected: true, onTap: () => taps++),
      ),
    );

    await tester.tap(find.text('Plomería'));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.byType(ManoChoiceChip)),
      matchesSemantics(
        label: 'Plomería',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets('a removable chip shows a quit control', (tester) async {
    var removed = 0;
    await tester.pumpWidget(
      _host(ManoChoiceChip(label: 'Chapinero', onRemove: () => removed++)),
    );

    await tester.tap(find.byTooltip('Quitar Chapinero'));
    expect(removed, 1);
  });
}
