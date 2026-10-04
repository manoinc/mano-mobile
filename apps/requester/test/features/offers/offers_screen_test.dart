import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';
import 'fake_service_catalog.dart';

const _route = '/home/service/svc-1/offers';

final _offers = [
  fakeOffer('fixed-high', amountCop: 150000, zone: 'Chapinero'),
  fakeOffer('hourly', rateType: RateType.hourly, amountCop: 45000),
  fakeOffer('fixed-low', amountCop: 90000, zone: 'Usaquén'),
];

Future<(FakeServiceCatalog, ProviderContainer)> _pump(
  WidgetTester tester, {
  List<ServiceOffer>? offers,
  bool fail = false,
}) async {
  final catalog = FakeServiceCatalog(
    services: const [fakeService],
    offers: offers ?? _offers,
  )..failOffers = fail;
  final container = await pumpRouterAt(
    tester,
    _route,
    overrides: [serviceCatalogProvider.overrideWithValue(catalog)],
  );
  return (catalog, container);
}

List<String> _cardAmounts(WidgetTester tester) => [
  for (final card in tester.widgetList<ManoOfferCard>(
    find.byType(ManoOfferCard),
  ))
    card.amountLabel,
];

void main() {
  testWidgets('heads the list with the service title', (tester) async {
    await _pump(tester);
    expect(find.text('Limpieza profunda'), findsOneWidget);
  });

  testWidgets('lists every offer cheapest first', (tester) async {
    await _pump(tester);
    expect(_cardAmounts(tester), [
      ManoFormat.cop(45000),
      ManoFormat.cop(90000),
      ManoFormat.cop(150000),
    ]);
  });

  testWidgets('shows pricing model, rate, zone and a neutral provider', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Profesional'), findsNWidgets(3));
    expect(find.text('Por hora'), findsWidgets);
    expect(find.text('/hora'), findsOneWidget);
    expect(find.text('precio fijo'), findsNWidgets(2));
    expect(find.text('Zona: Chapinero'), findsOneWidget);
    expect(find.text('Sin zona definida'), findsOneWidget);
  });

  testWidgets('filters by pricing model', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Por hora').first);
    await tester.pumpAndSettle();
    expect(_cardAmounts(tester), [ManoFormat.cop(45000)]);

    await tester.tap(find.text('Precio fijo').first);
    await tester.pumpAndSettle();
    expect(_cardAmounts(tester), [ManoFormat.cop(90000), ManoFormat.cop(150000)]);

    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    expect(_cardAmounts(tester), hasLength(3));
  });

  testWidgets('says so when a filter matches nothing', (tester) async {
    await _pump(tester, offers: [fakeOffer('only-fixed')]);
    await tester.tap(find.text('Por hora'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoOfferCard), findsNothing);
    expect(find.text('No hay ofertas con este tipo de precio'), findsOneWidget);
  });

  testWidgets('tapping an offer opens its booking', (tester) async {
    final (_, container) = await _pump(tester);
    await tester.tap(find.text('Zona: Usaquén'));
    await tester.pumpAndSettle();
    expect(routerPath(container), '/home/book/fixed-low');
  });

  testWidgets('"Agendar" opens the booking too', (tester) async {
    final (_, container) = await _pump(tester);
    await tester.tap(find.text('Agendar').first);
    await tester.pumpAndSettle();
    expect(routerPath(container), '/home/book/hourly');
  });

  testWidgets('shows an empty state when the service has no offers', (
    tester,
  ) async {
    await _pump(tester, offers: const []);
    expect(find.text('Aún no hay ofertas para este servicio'), findsOneWidget);
  });

  testWidgets('retries after an error', (tester) async {
    final (catalog, _) = await _pump(tester, fail: true);
    expect(find.text('No pudimos cargar las ofertas'), findsOneWidget);

    catalog.failOffers = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.byType(ManoOfferCard), findsNWidgets(3));
  });
}
