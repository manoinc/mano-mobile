import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_requester/screens/home_tab_screen.dart';
import 'package:mano_requester/shell/app_router.dart';
import 'package:mano_requester/shell/nav_shell.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../support/fake_session_repository.dart';

/// The real [requesterRouterProvider] on its own, without [ManoRoot]'s
/// doorway around it -- who gets to see this router is [ManoRoot]'s
/// decision, made before it is ever mounted; these tests are only about the
/// shape of the router itself.
Future<ProviderContainer> _pump(WidgetTester tester) async {
  final container = ProviderContainer.test(
    overrides: [
      sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: ManoTheme.light(),
          routerConfig: ref.watch(requesterRouterProvider),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

String _location(ProviderContainer container) => container
    .read(requesterRouterProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .toString();

void main() {
  testWidgets('opens onto /home inside the shell', (tester) async {
    final container = await _pump(tester);

    expect(_location(container), '/home');
    expect(find.byType(NavShell), findsOneWidget);
    expect(find.byType(HomeTabScreen), findsOneWidget);
  });

  test('the router is built once per container', () {
    final container = ProviderContainer.test(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
      ],
    );

    final GoRouter first = container.read(requesterRouterProvider);
    expect(container.read(requesterRouterProvider), same(first));
  });
}
