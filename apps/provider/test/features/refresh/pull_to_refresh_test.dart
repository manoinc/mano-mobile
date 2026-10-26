import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';
import '../services/services_fakes.dart';

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
    myQuotesProvider.overrideWith(
      (ref) =>
          count('quotes', () => ref.watch(leadRepositoryProvider).myQuotes()),
    ),
    myOffersProvider.overrideWith(
      (ref) =>
          count('offers', () => ref.watch(offerManagementProvider).myOffers()),
    ),
    myAvailabilityRulesProvider.overrideWith(
      (ref) => count(
        'rules',
        () => ref.watch(availabilityRepositoryProvider).myRules(),
      ),
    ),
  ];
}

Future<_Fetches> _pumpAt(WidgetTester tester, String location) async {
  final fetches = _Fetches();
  await pumpRouterAt(
    tester,
    location,
    session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    overrides: [
      ...fetches.overrides,
      // The catalog has no offline mock.
      serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
    ],
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
  testWidgets('pulling Inicio refetches requests, jobs and quotes', (
    tester,
  ) async {
    final fetches = await _pumpAt(tester, '/home');
    final before = Map.of(fetches.counts);

    await _pull(tester);

    expect(fetches.counts['requests'], before['requests']! + 1);
    expect(fetches.counts['jobs'], before['jobs']! + 1);
    expect(fetches.counts['quotes'], (before['quotes'] ?? 0) + 1);
  });

  testWidgets('pulling the Agenda refetches the jobs', (tester) async {
    final fetches = await _pumpAt(tester, '/agenda');
    final before = fetches.counts['jobs']!;

    await _pull(tester);

    expect(fetches.counts['jobs'], before + 1);
  });

  testWidgets('pulling Disponibilidad refetches the weekly hours', (
    tester,
  ) async {
    final fetches = await _pumpAt(tester, '/agenda');
    await tester.tap(find.text('Disponibilidad'));
    await tester.pumpAndSettle();
    final before = fetches.counts['rules']!;

    await _pull(tester);

    expect(fetches.counts['rules'], before + 1);
  });

  testWidgets('pulling Mis servicios refetches the offers', (tester) async {
    final fetches = await _pumpAt(tester, '/profile/services');
    final before = fetches.counts['offers']!;

    await _pull(tester);

    expect(fetches.counts['offers'], before + 1);
  });
}
