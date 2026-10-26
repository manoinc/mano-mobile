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
  testWidgets('pulling Servicios refetches requests and jobs', (tester) async {
    final fetches = await _pumpActividad(tester);
    final before = Map.of(fetches.counts);

    await _pull(tester);

    expect(fetches.counts['requests'], before['requests']! + 1);
    expect(fetches.counts['jobs'], (before['jobs'] ?? 0) + 1);
  });

  testWidgets('pulling Proyectos refetches the projects', (tester) async {
    final fetches = await _pumpActividad(tester);
    await tester.tap(find.text('Proyectos'));
    await tester.pumpAndSettle();
    final before = fetches.counts['projects']!;

    await _pull(tester);

    expect(fetches.counts['projects'], before + 1);
  });
}
