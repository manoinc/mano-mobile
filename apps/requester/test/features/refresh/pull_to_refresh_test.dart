import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

/// How often each read reached its repository.
final class _Fetches {
  final counts = <String, int>{};

  T count<T>(String name, T Function() fetch) {
    counts[name] = (counts[name] ?? 0) + 1;
    return fetch();
  }

  // The real reads, counted.
  List<Override> get overrides => [
    myServiceRequestsProvider.overrideWith(
      (ref) => count(
        'requests',
        () => ref.watch(serviceRequestRepositoryProvider).mine(),
      ),
    ),
    myJobsProvider.overrideWith(
      (ref) => count('jobs', () => ref.watch(jobRepositoryProvider).mine()),
    ),
    myProjectsProvider.overrideWith(
      (ref) =>
          count('projects', () => ref.watch(projectRepositoryProvider).mine()),
    ),
  ];
}

Future<_Fetches> _pumpActividad(WidgetTester tester) async {
  final fetches = _Fetches();
  await pumpRouterAt(
    tester,
    '/projects',
    session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    overrides: fetches.overrides,
  );
  return fetches;
}

Future<void> _pull(WidgetTester tester) async {
  await tester.fling(
    find.byType(ManoPullToRefresh).first,
    const Offset(0, 400),
    1000,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pulling Actividad refetches requests, jobs and projects', (
    tester,
  ) async {
    final fetches = await _pumpActividad(tester);
    final before = Map.of(fetches.counts);

    await _pull(tester);

    for (final read in ['requests', 'jobs', 'projects']) {
      expect(fetches.counts[read], before[read]! + 1, reason: read);
    }
  });
}
