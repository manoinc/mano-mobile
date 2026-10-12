import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  const items = [
    ManoNavItem(icon: Icons.home_outlined, label: 'Inicio'),
    ManoNavItem(icon: Icons.work_outline, label: 'Trabajos'),
    ManoNavItem(icon: Icons.chat_bubble_outline, label: 'Mensajes'),
    ManoNavItem(icon: Icons.person_outline, label: 'Perfil'),
  ];

  group('the bottom nav bar', () {
    testWidgets('renders every item label', (tester) async {
      await tester.pumpWidget(
        _host(
          ManoBottomNavBar(
            items: items,
            currentIndex: 0,
            onTap: (_) {},
            onActionTap: () {},
          ),
        ),
      );

      for (final item in items) {
        expect(find.text(item.label), findsOneWidget);
      }
    });

    testWidgets('renders a distinct center action, separate from item icons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ManoBottomNavBar(
            items: items,
            currentIndex: 0,
            onTap: (_) {},
            onActionTap: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets(
      'tapping a side item calls onTap with its index, never onActionTap',
      (tester) async {
        int? tapped;
        var actionTaps = 0;
        await tester.pumpWidget(
          _host(
            ManoBottomNavBar(
              items: items,
              currentIndex: 0,
              onTap: (index) => tapped = index,
              onActionTap: () => actionTaps++,
            ),
          ),
        );

        await tester.tap(find.text(items[2].label));
        await tester.pumpAndSettle();

        expect(tapped, 2);
        expect(actionTaps, 0);
      },
    );

    testWidgets('tapping the center action calls onActionTap, never onTap', (
      tester,
    ) async {
      var tapCalls = 0;
      var actionTaps = 0;
      await tester.pumpWidget(
        _host(
          ManoBottomNavBar(
            items: items,
            currentIndex: 0,
            onTap: (_) => tapCalls++,
            onActionTap: () => actionTaps++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(actionTaps, 1);
      expect(tapCalls, 0);
    });

    testWidgets('tints the selected item flame and an unselected item faint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ManoBottomNavBar(
            items: items,
            currentIndex: 1,
            onTap: (_) {},
            onActionTap: () {},
          ),
        ),
      );

      final selected = tester.widget<Icon>(find.byIcon(items[1].icon));
      final unselected = tester.widget<Icon>(find.byIcon(items[0].icon));

      expect(selected.color, ManoColors.flame);
      expect(unselected.color, ManoColors.faint);
    });

    testWidgets(
      'tapping a side item shows a brief expanding ripple, then it fades away',
      (tester) async {
        await tester.pumpWidget(
          _host(
            ManoBottomNavBar(
              items: items,
              currentIndex: 0,
              onTap: (_) {},
              onActionTap: () {},
            ),
          ),
        );

        // At rest, no ripple is mounted at all -- it exists only mid-animation.
        expect(find.byKey(const Key('mano-nav-item-ripple')), findsNothing);

        await tester.tap(find.text(items[2].label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final earlySize = tester
            .getSize(find.byKey(const Key('mano-nav-item-ripple')))
            .width;

        await tester.pump(const Duration(milliseconds: 150));
        final laterSize = tester
            .getSize(find.byKey(const Key('mano-nav-item-ripple')))
            .width;

        expect(
          laterSize,
          greaterThan(earlySize),
          reason: 'a droplet ripple spreads outward as it plays',
        );

        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mano-nav-item-ripple')),
          findsNothing,
          reason: 'the ripple fades out and unmounts once it finishes',
        );
      },
    );

    testWidgets('tapping a side item never rotates it', (tester) async {
      await tester.pumpWidget(
        _host(
          ManoBottomNavBar(
            items: items,
            currentIndex: 0,
            onTap: (_) {},
            onActionTap: () {},
          ),
        ),
      );

      bool rotated(String label) => tester
          .widgetList<Transform>(
            find.ancestor(of: find.text(label), matching: find.byType(Transform)),
          )
          .any((t) => t.transform.storage[1] != 0);

      await tester.tap(find.text(items[2].label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(rotated(items[2].label), isFalse);

      await tester.pumpAndSettle();
      expect(rotated(items[2].label), isFalse);
    });
  });
}
