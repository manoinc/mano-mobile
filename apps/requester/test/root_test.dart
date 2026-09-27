import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/root.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'support/fake_session_repository.dart';

/// [ManoRoot] itself, minus the native splash plugin -- animations off, the
/// same reason [ManoRoot._opened] being static forces every suite that pumps
/// it more than once. Pumping [ManoRoot] directly (not `RequesterApp`) tests
/// only what this widget owns: the opening's ready-gating and crash handling,
/// independent of where the doorway or the shell send you next.
Future<void> _pump(WidgetTester tester, SessionRepository repository) {
  ManoRoot.resetOpening();
  return tester.pumpWidget(
    ProviderScope(
      overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: ManoTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const ManoRoot(),
      ),
    ),
  );
}

void main() {
  testWidgets('the opening holds while the session is still restoring', (
    tester,
  ) async {
    final restore = Completer<Result<Session?, AuthFailure>>();
    await _pump(tester, FakeSessionRepository(onRestore: () => restore.future));
    await tester.pumpAndSettle();

    expect(tester.widget<ManoOpening>(find.byType(ManoOpening)).ready, isFalse);

    restore.complete(const Ok(null));
    await tester.pumpAndSettle();

    expect(tester.widget<ManoOpening>(find.byType(ManoOpening)).ready, isTrue);
  });

  testWidgets('a session that throws is reported as a crash', (tester) async {
    await _pump(
      tester,
      FakeSessionRepository(onRestore: () async => throw StateError('boom')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Algo se rompió.'), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
  });
}
