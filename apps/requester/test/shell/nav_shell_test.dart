import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_requester/shell/create_action_sheet.dart';
import 'package:mano_requester/shell/nav_shell.dart';
import 'package:mano_ui/mano_ui.dart';

/// A real [GoRouter] with a real [StatefulNavigationShell], so these tests
/// exercise go_router's branch switching rather than a stand-in for it. The
/// branch pages are local placeholders, not the app's tab screens, so this
/// file does not change when those screens grow real content.
GoRouter _router() => GoRouter(
  initialLocation: '/a',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          NavShell(navigationShell: navigationShell),
      branches: [
        for (final path in ['/a', '/b', '/c', '/d'])
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: path,
                builder: (context, state) => Text('page $path'),
              ),
            ],
          ),
      ],
    ),
  ],
);

Future<GoRouter> _pump(WidgetTester tester) async {
  final router = _router();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: ManoTheme.light(), routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

int _currentIndex(WidgetTester tester) =>
    tester.widget<ManoBottomNavBar>(find.byType(ManoBottomNavBar)).currentIndex;

void main() {
  testWidgets('starts on the first branch', (tester) async {
    await _pump(tester);

    expect(find.text('page /a'), findsOneWidget);
    expect(_currentIndex(tester), 0);
  });

  testWidgets('tapping a nav item switches to its branch', (tester) async {
    final router = await _pump(tester);

    await tester.tap(find.text('Bandeja'));
    await tester.pumpAndSettle();

    expect(find.text('page /c'), findsOneWidget);
    expect(_currentIndex(tester), 2);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/c',
    );

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('page /d'), findsOneWidget);
    expect(_currentIndex(tester), 3);
  });

  testWidgets('CREATE opens the action sheet without changing the tab', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Proyectos'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(CreateActionSheet), findsOneWidget);
    expect(find.text('Publicar un trabajo'), findsOneWidget);
    expect(_currentIndex(tester), 1);
  });

  testWidgets('the action sheet closes from its close control', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateActionSheet), findsNothing);
    expect(_currentIndex(tester), 0);
  });
}
