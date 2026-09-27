import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_requester/screens/home_tab_screen.dart';
import 'package:mano_requester/screens/sign_in_screen.dart';
import 'package:mano_requester/shell/app_router.dart';
import 'package:mano_requester/shell/nav_shell.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../support/fake_session_repository.dart';

/// The real [requesterRouterProvider], driven by a real [sessionProvider]
/// over a fake repository. Deliberately without [ManoOpening]: these tests are
/// about where the router sends you, not about what the opening hides.
Future<ProviderContainer> _pump(
  WidgetTester tester,
  SessionRepository repository,
) async {
  final container = ProviderContainer.test(
    overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
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
  testWidgets('signed out resolves to /sign-in', (tester) async {
    final container = await _pump(tester, FakeSessionRepository());

    expect(_location(container), '/sign-in');
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(NavShell), findsNothing);
  });

  testWidgets('signed in resolves to /home inside the shell', (tester) async {
    final container = await _pump(
      tester,
      FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );

    expect(_location(container), '/home');
    expect(find.byType(NavShell), findsOneWidget);
    expect(find.byType(HomeTabScreen), findsOneWidget);
  });

  testWidgets('signed in and sent to /sign-in is redirected to /home', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );

    container.read(requesterRouterProvider).go('/sign-in');
    await tester.pumpAndSettle();

    expect(_location(container), '/home');
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(HomeTabScreen), findsOneWidget);
  });

  testWidgets('still restoring does not redirect', (tester) async {
    final restore = Completer<Result<Session?, AuthFailure>>();
    final container = await _pump(
      tester,
      FakeSessionRepository(onRestore: () => restore.future),
    );

    // Nothing to redirect to yet; the opening is what covers this.
    expect(_location(container), '/home');

    restore.complete(const Ok(null));
    await tester.pumpAndSettle();

    expect(_location(container), '/sign-in');
  });

  testWidgets('signing in moves from /sign-in to /home', (tester) async {
    final container = await _pump(
      tester,
      FakeSessionRepository(onSignIn: () async => Ok(fakeSession())),
    );

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(_location(container), '/home');
    expect(find.byType(HomeTabScreen), findsOneWidget);
  });

  testWidgets('signing out moves back to /sign-in', (tester) async {
    final container = await _pump(
      tester,
      FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );

    await container.read(sessionProvider.notifier).signOut();
    await tester.pumpAndSettle();

    expect(_location(container), '/sign-in');
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('a failed sign-in shows its notice, and dismissing clears it', (
    tester,
  ) async {
    // The failure lives in the session, not in the route, so staying on
    // /sign-in must still re-render the screen with it.
    await _pump(
      tester,
      FakeSessionRepository(
        onSignIn: () async => const Err(SignInRejected(reason: '401')),
      ),
    );

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos completar el inicio de sesión. Vuelve a intentarlo.'),
      findsOneWidget,
    );
    expect(find.byType(ManoNotice), findsOneWidget);

    tester
        .widget<ManoNotice>(find.byType(ManoNotice))
        .onDismiss!
        .call();
    await tester.pumpAndSettle();

    expect(find.byType(ManoNotice), findsNothing);
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
