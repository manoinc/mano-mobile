import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

Widget _darkHost(Widget child) => MaterialApp(
  theme: ManoTheme.dark(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('the project filter tabs', () {
    const labels = ['All', 'Scheduled', 'In Progress', 'Completed', 'Canceled'];

    testWidgets('renders a pill for every label', (tester) async {
      await tester.pumpWidget(
        _host(
          ManoProjectFilterTabs(
            labels: labels,
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      );

      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('calls onSelected once with the tapped index', (tester) async {
      final selections = <int>[];
      await tester.pumpWidget(
        _host(
          ManoProjectFilterTabs(
            labels: labels,
            selectedIndex: 0,
            onSelected: selections.add,
          ),
        ),
      );

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(selections, [3]);
    });

    testWidgets(
      'gives the selected pill a different background than the rest',
      (tester) async {
        await tester.pumpWidget(
          _host(
            ManoProjectFilterTabs(
              labels: labels,
              selectedIndex: 1,
              onSelected: (_) {},
            ),
          ),
        );

        final selected = tester.widget<Container>(
          find.byKey(const Key('mano-project-filter-tab-1')),
        );
        final unselected = tester.widget<Container>(
          find.byKey(const Key('mano-project-filter-tab-0')),
        );

        final selectedDecoration = selected.decoration! as BoxDecoration;
        final unselectedDecoration = unselected.decoration! as BoxDecoration;

        expect(selectedDecoration.color, ManoColors.flame);
        expect(unselectedDecoration.color, isNot(ManoColors.flame));
        expect(selectedDecoration.color, isNot(unselectedDecoration.color));
      },
    );

    testWidgets(
      'gives the unselected pill a theme-aware background and text color in dark mode, not the hard-coded light pair',
      (tester) async {
        await tester.pumpWidget(
          _darkHost(
            ManoProjectFilterTabs(
              labels: labels,
              selectedIndex: 1,
              onSelected: (_) {},
            ),
          ),
        );

        final unselected = tester.widget<Container>(
          find.byKey(const Key('mano-project-filter-tab-0')),
        );
        final unselectedDecoration = unselected.decoration! as BoxDecoration;
        final darkScheme = ManoTheme.dark().colorScheme;

        expect(unselectedDecoration.color, isNot(ManoColors.stone));
        expect(unselectedDecoration.color, darkScheme.surfaceContainerHighest);

        final unselectedLabel = tester.widget<Text>(find.text('All'));
        expect(unselectedLabel.style?.color, isNot(ManoColors.muted));
        expect(unselectedLabel.style?.color, darkScheme.onSurface);
      },
    );
  });
}
