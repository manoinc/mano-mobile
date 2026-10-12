import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/services/my_services_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';
import 'services_fakes.dart';

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester,
    FakeOfferManagement offers,
  ) => pumpRouterAt(
    tester,
    '/profile/services',
    overrides: [
      offerManagementProvider.overrideWithValue(offers),
      serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
    ],
  );

  testWidgets('lists offers with title, pricing, zone and status', (
    tester,
  ) async {
    await pump(
      tester,
      FakeOfferManagement([
        offer('o1'),
        offer(
          'o2',
          jobServiceId: 'unknown',
          rateType: RateType.hourly,
          amountCop: 45000,
          zone: '',
          status: OfferStatus.paused,
        ),
      ]),
    );

    expect(find.byType(MyServicesScreen), findsOneWidget);
    expect(find.text('Mis servicios'), findsOneWidget);
    expect(find.byType(ManoOfferCard), findsNWidgets(2));

    final first = tester.widget<ManoOfferCard>(
      find.byType(ManoOfferCard).first,
    );
    expect(first.title, 'Limpieza profunda');
    expect(first.subtitle, 'Precio fijo');
    expect(first.amountLabel, ManoFormat.cop(120000));
    expect(first.rateLabel, 'precio fijo');
    expect(first.zone, 'Zona: Chapinero');

    final second = tester.widget<ManoOfferCard>(
      find.byType(ManoOfferCard).last,
    );
    expect(second.title, 'Servicio');
    expect(second.subtitle, 'Por hora');
    expect(second.rateLabel, '/hora');
    expect(second.zone, 'Sin zona definida');

    expect(find.widgetWithText(ManoStatusChip, 'Activa'), findsOneWidget);
    expect(find.widgetWithText(ManoStatusChip, 'Pausada'), findsOneWidget);
  });

  testWidgets('tapping an offer opens its editor', (tester) async {
    final c = await pump(tester, FakeOfferManagement([offer('o1')]));
    await tester.tap(find.byType(ManoOfferCard));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/profile/services/offer/o1');
  });

  testWidgets('the availability entry opens the calendar', (tester) async {
    final c = await pump(tester, FakeOfferManagement([offer('o1')]));
    await tester.tap(find.text('Disponibilidad y calendario'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/agenda/availability');
  });

  testWidgets('a new offer is one tap away from the list', (tester) async {
    final c = await pump(tester, FakeOfferManagement([offer('o1')]));
    await tester.tap(find.text('Nueva oferta'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/profile/services/new');
  });

  testWidgets('no offers invites publishing the first one', (tester) async {
    final c = await pump(tester, FakeOfferManagement());
    expect(find.text('Publicar mi primer servicio'), findsOneWidget);
    await tester.tap(find.text('Publicar mi primer servicio'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/profile/services/new');
  });

  testWidgets('a failed load can be retried', (tester) async {
    final offers = FakeOfferManagement([offer('o1')])..failList = true;
    await pump(tester, offers);
    expect(find.text('No pudimos cargar tus servicios'), findsOneWidget);

    offers.failList = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoOfferCard), findsOneWidget);
  });
}
