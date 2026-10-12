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
  _FakeCatalogRepository();

  static const fakeCategories = [
    ServiceCategory(id: 'cleaning', label: 'Limpieza', iconKey: 'cleaning'),
    ServiceCategory(id: 'plumbing', label: 'Plomería', iconKey: 'plumbing'),
  ];

  // Four per category, so each category earns its own rail.
  static final fakeListings = [
    for (final c in fakeCategories)
      for (var i = 1; i <= 4; i++)
        ServiceListing(
          id: '${c.id}-$i',
          title: '${c.label} $i',
          categoryId: c.id,
          professionalName: 'Pro $i',
          professionalPhotoUrl: 'https://example.com/pro.jpg',
          photoUrl: 'https://example.com/${c.id}.jpg',
          priceFromCents: 1000000 * i,
          rating: 4.0 + i / 10,
          reviewCount: i,
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
        catalogRepositoryProvider.overrideWithValue(_FakeCatalogRepository()),
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
    catalogRepositoryProvider.overrideWithValue(_FakeCatalogRepository()),
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

    expect(find.text('Limpieza'), findsWidgets);
    expect(find.text('Plomería'), findsWidgets);
  });

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }

  testWidgets('shows a rail per section with its header', (tester) async {
    await _host(tester);

    expect(find.text('Populares cerca de ti'), findsOneWidget);
    await scrollTo(tester, find.text('Mejor calificados'));
    expect(find.text('Mejor calificados'), findsOneWidget);
    await scrollTo(tester, find.byType(ManoSectionHeader).last);
    expect(find.byType(ManoListingCarousel), findsWidgets);
    expect(find.byType(ManoSectionHeader).evaluate().length, greaterThan(2));
  });

  testWidgets('renders listing titles and price labels', (tester) async {
    await _host(tester);

    expect(find.text('Limpieza 1'), findsWidgets);
    expect(find.textContaining('10.000'), findsWidgets);
  });

  testWidgets('a category rail header opens search filtered to it', (
    tester,
  ) async {
    final container = await _hostRouted(tester);

    final header = find.widgetWithText(ManoSectionHeader, 'Plomería');
    await scrollTo(tester, header);
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(header);
    await tester.pumpAndSettle();

    expect(routerPath(container), '/home/search');
    expect(_query(container)['category'], 'plumbing');
  });

  testWidgets('the popular header opens unfiltered search', (tester) async {
    final container = await _hostRouted(tester);

    await tester.tap(
      find.widgetWithText(ManoSectionHeader, 'Populares cerca de ti'),
    );
    await tester.pumpAndSettle();

    expect(routerPath(container), '/home/search');
    expect(_query(container), isEmpty);
  });

  testWidgets('a guest gets a neutral headline instead of a greeting', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(_FakeCatalogRepository()),
        ],
        child: MaterialApp(
          theme: ManoTheme.light(),
          home: const HomeTabScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Encuentra ayuda para tu hogar'), findsOneWidget);
    expect(find.textContaining('Hola'), findsNothing);
  });

  testWidgets('tapping a category opens search filtered to it', (tester) async {
    final container = await _hostRouted(tester);

    await tester.tap(find.byType(ManoCategoryChip).first);
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

    final card = find.text('Limpieza 1').first;
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('Muy pronto'), findsOneWidget);
  });
}
