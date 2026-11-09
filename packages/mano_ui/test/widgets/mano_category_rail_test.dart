import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  const items = [
    ManoCategoryRailItem(
      id: 'cleaning',
      icon: Icons.cleaning_services_outlined,
      label: 'Limpieza',
    ),
    ManoCategoryRailItem(
      id: 'plumbing',
      icon: Icons.plumbing_outlined,
      label: 'Plomería',
    ),
    ManoCategoryRailItem(
      id: 'electrical',
      icon: Icons.electrical_services_outlined,
      label: 'Electricidad',
    ),
  ];

  group('the category rail', () {
    testWidgets('grows with enlarged text instead of overflowing', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        _host(ManoCategoryRail(items: items, onSelected: (_) {})),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders every item label', (tester) async {
      await tester.pumpWidget(
        _host(ManoCategoryRail(items: items, onSelected: (_) {})),
      );

      for (final item in items) {
        expect(find.text(item.label), findsOneWidget);
      }
    });

    testWidgets('tapping the chip at index 1 selects that item\'s id', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        _host(
          ManoCategoryRail(items: items, onSelected: (id) => selected = id),
        ),
      );

      await tester.tap(find.text(items[1].label));
      await tester.pumpAndSettle();

      expect(selected, items[1].id);
    });
  });
}
