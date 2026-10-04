import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/screens/home_tab_screen.dart';
import 'package:mano_requester/shell/app_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../features/explore/fake_service_catalog.dart';
import '../support/fake_session_repository.dart';
import '../support/pump_app.dart';

/// A tiny in-memory catalog: two categories and a listing in each.
final class _FakeCatalogRepository implements CatalogRepository {
  const _FakeCatalogRepository();

  static const fakeCategories = [
    ServiceCategory(id: 'cleaning', label: 'Limpieza', iconKey: 'cleaning'),
    ServiceCategory(id: 'plumbing', label: 'Plomería', iconKey: 'plumbing'),
  ];

  static const fakeListings = [
    ServiceListing(
      id: 'cleaning-1',
      title: 'Limpieza profunda',
      categoryId: 'cleaning',
      professionalName: 'Ana Torres',
      professionalPhotoUrl: 'https://example.com/ana.jpg',
      photoUrl: 'https://example.com/cleaning.jpg',
      priceFromCents: 8000000,
      rating: 4.8,
    ),
    ServiceListing(
      id: 'plumbing-1',
      title: 'Reparación de tuberías',
      categoryId: 'plumbing',
      professionalName: 'Luis Pérez',
      professionalPhotoUrl: 'https://example.com/luis.jpg',
      photoUrl: 'https://example.com/plumbing.jpg',
      priceFromCents: 7500000,
      rating: 4.5,
    ),
  ];

  @override
  Future<List<ServiceCategory>> categories() async => fakeCategories;

  @override
  Future<List<ServiceListing>> popularListings() async => fakeListings;
}

Future<void> _host(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(
          const _FakeCatalogRepository(),
        ),
        sessionRepositoryProvider.overrideWithValue(
          FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
        ),
      ],
      child: MaterialApp(theme: ManoTheme.light(), home: const HomeTabScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<ProviderContainer> _hostRouted(WidgetTester tester) => pumpRouterAt(
  tester,
  '/home',
  overrides: [
    catalogRepositoryProvider.overrideWithValue(const _FakeCatalogRepository()),
    serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
  ],
);

Map<String, String> _query(ProviderContainer container) =>
    container.read(requesterRouterProvider).state.uri.queryParameters;

void main() {
  testWidgets('greets the signed-in user by name', (tester) async {
    await _host(tester);

    expect(find.text('Hola, mano-test'), findsOneWidget);
  });

  testWidgets('renders every category label', (tester) async {
    await _host(tester);

    expect(find.text('Limpieza'), findsOneWidget);
    expect(find.text('Plomería'), findsOneWidget);
  });

  testWidgets('renders every listing title and price label', (tester) async {
    await _host(tester);

    expect(find.text('Limpieza profunda'), findsOneWidget);
    expect(find.textContaining('80.000'), findsOneWidget);
    expect(find.text('Reparación de tuberías'), findsOneWidget);
    expect(find.textContaining('75.000'), findsOneWidget);
  });

  testWidgets('tapping a category opens search filtered to it', (tester) async {
    final container = await _hostRouted(tester);

    await tester.tap(find.text('Limpieza'));
    await tester.pumpAndSettle();

    expect(routerPath(container), '/home/search');
    expect(_query(container)['category'], 'cleaning');
  });

  testWidgets('"Ver todo" opens search with no filter', (tester) async {
    final container = await _hostRouted(tester);

    await tester.tap(find.text('Ver todo'));
    await tester.pumpAndSettle();

    expect(routerPath(container), '/home/search');
    expect(_query(container), isEmpty);
  });

  testWidgets('the search pill opens search', (tester) async {
    final container = await _hostRouted(tester);

    await tester.tap(find.byType(ManoSearchPill));
    await tester.pumpAndSettle();

    expect(routerPath(container), '/home/search');
  });

  testWidgets('tapping the address pill shows the stub notice', (tester) async {
    await _host(tester);

    await tester.tap(find.byType(ManoAddressPill));
    await tester.pumpAndSettle();

    expect(find.text('Muy pronto'), findsOneWidget);
  });

  testWidgets('tapping a listing card shows the stub notice', (tester) async {
    await _host(tester);

    final card = find.text('Limpieza profunda');
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('Muy pronto'), findsOneWidget);
  });
}
