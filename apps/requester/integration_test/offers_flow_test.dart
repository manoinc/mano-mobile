import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:mano_requester/features/offers/offers_screen.dart';
import 'package:mano_requester/features/provider_profile/provider_profile_screen.dart';
import 'package:mano_requester/main.dart';
import 'package:mano_requester/shell/app_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../test/features/offers/fake_service_catalog.dart';
import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a requester filters offers by hour and opens one to book', (
    tester,
  ) async {
    final catalog = FakeServiceCatalog(
      services: const [fakeService],
      offers: [
        fakeOffer('fixed', amountCop: 120000, zone: 'Chapinero'),
        fakeOffer('hourly', rateType: RateType.hourly, amountCop: 45000),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        offlineMarketplaceProvider.overrideWithValue(true),
        manoConfigProvider.overrideWithValue(testConfig),
        sessionRepositoryProvider.overrideWithValue(
          FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
        ),
        serviceCatalogProvider.overrideWithValue(catalog),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RequesterApp(),
      ),
    );
    await tester.pumpAndSettle();

    final router = container.read(requesterRouterProvider);
    router.go('/home/service/${fakeService.id}/offers');
    await tester.pumpAndSettle();
    expect(find.byType(OffersScreen), findsOneWidget);
    expect(find.text('Limpieza profunda'), findsOneWidget);

    await tester.tap(find.text('Por hora').first);
    await tester.pumpAndSettle();
    expect(find.byType(ManoOfferCard), findsOneWidget);

    await tester.tap(find.byType(ManoOfferCard));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/home/book/hourly');
  });

  testWidgets('a requester opens a provider from an offer and writes to them', (
    tester,
  ) async {
    final catalog = FakeServiceCatalog(
      services: const [fakeService],
      offers: [fakeOffer('1', amountCop: 120000, zone: 'Chapinero')],
    );
    final container = ProviderContainer(
      overrides: [
        offlineMarketplaceProvider.overrideWithValue(true),
        manoConfigProvider.overrideWithValue(testConfig),
        sessionRepositoryProvider.overrideWithValue(
          FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
        ),
        serviceCatalogProvider.overrideWithValue(catalog),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RequesterApp(),
      ),
    );
    await tester.pumpAndSettle();

    final router = container.read(requesterRouterProvider);
    router.go('/home/service/${fakeService.id}/offers');
    await tester.pumpAndSettle();
    expect(find.textContaining('4,8 · 4', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Profesional'));
    await tester.pumpAndSettle();
    expect(find.byType(ProviderProfileScreen), findsOneWidget);
    expect(find.text('Andrés Castro'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('Ver las'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.textContaining('Ver las'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/provider/provider-1/reviews');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escribir'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/inbox/conv-with-provider-1');
  });
}
