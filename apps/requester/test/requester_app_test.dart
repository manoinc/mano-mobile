import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/main.dart';
import 'package:mano_requester/screens/home_tab_screen.dart';
import 'package:mano_requester/screens/sign_in_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'support/fake_session_repository.dart';

/// The whole app as `main()` builds it, minus the native splash: the routed
/// screen wrapped in [ManoOpening] by `MaterialApp.router`'s builder.
Future<void> _pump(WidgetTester tester, SessionRepository repository) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
        child: const RequesterApp(),
      ),
    );

void main() {
  testWidgets('opens onto sign-in once a signed-out session resolves', (
    tester,
  ) async {
    await _pump(tester, FakeSessionRepository());
    await tester.pumpAndSettle();

    expect(find.byType(ManoOpening), findsOneWidget);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('opens onto the shell when a session restores', (tester) async {
    await _pump(
      tester,
      FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeTabScreen), findsOneWidget);
  });

  testWidgets('the opening holds while the session is still restoring', (
    tester,
  ) async {
    final restore = Completer<Result<Session?, AuthFailure>>();
    await _pump(tester, FakeSessionRepository(onRestore: () => restore.future));
    await tester.pumpAndSettle();

    expect(
      tester.widget<ManoOpening>(find.byType(ManoOpening)).ready,
      isFalse,
    );

    restore.complete(const Ok(null));
    await tester.pumpAndSettle();

    expect(tester.widget<ManoOpening>(find.byType(ManoOpening)).ready, isTrue);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('a session that throws is reported as a crash', (tester) async {
    await _pump(
      tester,
      FakeSessionRepository(onRestore: () async => throw StateError('boom')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Algo se rompió.'), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
  });
}
