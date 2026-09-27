import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('the category chip', () {
    testWidgets('renders the given label', (tester) async {
      await tester.pumpWidget(
        _host(
          ManoCategoryChip(
            icon: Icons.cleaning_services_outlined,
            label: 'Limpieza',
            selected: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Limpieza'), findsOneWidget);
    });

    testWidgets('fires onTap once when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ManoCategoryChip(
            icon: Icons.cleaning_services_outlined,
            label: 'Limpieza',
            selected: false,
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(ManoCategoryChip));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('tints a selected chip flame and an unselected one faint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ManoCategoryChip(
            icon: Icons.cleaning_services_outlined,
            label: 'Limpieza',
            selected: true,
            onTap: () {},
          ),
        ),
      );
      final selectedIcon = tester.widget<Icon>(
        find.byIcon(Icons.cleaning_services_outlined),
      );

      await tester.pumpWidget(
        _host(
          ManoCategoryChip(
            icon: Icons.cleaning_services_outlined,
            label: 'Limpieza',
            selected: false,
            onTap: () {},
          ),
        ),
      );
      final unselectedIcon = tester.widget<Icon>(
        find.byIcon(Icons.cleaning_services_outlined),
      );

      expect(selectedIcon.color, ManoColors.flame);
      expect(unselectedIcon.color, ManoColors.faint);
      expect(selectedIcon.color, isNot(unselectedIcon.color));
    });
  });
}
