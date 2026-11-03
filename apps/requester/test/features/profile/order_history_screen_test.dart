import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

final class _NoJobs implements JobRepository {
  @override
  Future<List<Job>> mine({JobStatus? status}) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('lists finished and cancelled jobs, newest first', (
    tester,
  ) async {
    final container = await pumpRouterAt(
      tester,
      '/profile/history',
      session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );
    final history = await container.read(orderHistoryProvider.future);
    expect(history, isNotEmpty);

    final cards = tester
        .widgetList<ManoProjectCard>(find.byType(ManoProjectCard))
        .map((c) => (c.key! as ValueKey<String>).value)
        .toList();
    expect(cards.first, 'history-job-${history.first.id}');
    expect(find.text('Programado'), findsNothing);
  });

  testWidgets('a job opens its detail inside Perfil', (tester) async {
    final container = await pumpRouterAt(
      tester,
      '/profile/history',
      session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );
    final first = (await container.read(orderHistoryProvider.future)).first;

    await tester.tap(find.byKey(Key('history-job-${first.id}')));
    await tester.pumpAndSettle();

    expect(routerPath(container), '/profile/history/job/${first.id}');
    expect(find.text('Trabajo'), findsOneWidget);
  });

  testWidgets('says so when there is no history yet', (tester) async {
    await pumpRouterAt(
      tester,
      '/profile/history',
      overrides: [jobRepositoryProvider.overrideWithValue(_NoJobs())],
    );

    expect(find.byType(ManoEmptyState), findsOneWidget);
    expect(find.text('Explorar servicios'), findsOneWidget);
  });
}
