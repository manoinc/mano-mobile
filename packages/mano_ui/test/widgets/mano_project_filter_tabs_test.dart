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
  group('at 360 dp with 1.3x text', () {
    const segments = ['Solicitudes', 'Proyectos', 'Mis cotizaciones'];

    Future<void> pumpNarrow(WidgetTester tester, ValueChanged<int> onTap) {
      tester.view
        ..physicalSize = const Size(360, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      return tester.pumpWidget(
        MaterialApp(
          theme: ManoTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(ManoSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ManoProjectFilterTabs(
                      labels: segments,
                      selectedIndex: 0,
                      onSelected: onTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('pills grow with the text instead of clipping it', (
      tester,
    ) async {
      await pumpNarrow(tester, (_) {});

      final pill = tester.getSize(
        find.byKey(const Key('mano-project-filter-tab-0')),
      );
      final label = tester.getSize(find.text('Solicitudes'));
      expect(
        pill.height,
        greaterThanOrEqualTo(label.height + 2 * ManoSpacing.sm),
      );
    });

    testWidgets('a cut-off pill scrolls fully into view when tapped', (
      tester,
    ) async {
      final taps = <int>[];
      await pumpNarrow(tester, taps.add);

      final second = find.byKey(const Key('mano-project-filter-tab-1'));
      expect(tester.getRect(second).right, greaterThan(360));

      await tester.tapAt(tester.getRect(second).topLeft + const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(taps, [1]);
      final rect = tester.getRect(second);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(360));
    });
  });

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
