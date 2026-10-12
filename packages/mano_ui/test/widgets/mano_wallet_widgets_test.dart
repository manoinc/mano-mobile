import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('balance hero shows the number, unit, note and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ManoBalanceHero(
          amount: '25',
          unit: 'Mano coins',
          note: '≈ \$50.000',
          actions: Text('acciones'),
        ),
      ),
    );
    expect(find.text('25'), findsOneWidget);
    expect(find.text('Mano coins'), findsOneWidget);
    expect(find.text('≈ \$50.000'), findsOneWidget);
    expect(find.text('acciones'), findsOneWidget);
  });

  testWidgets('activity tile shows title, subtitle and amount', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ManoActivityTile(
          icon: Icons.add,
          title: 'Recarga',
          subtitle: 'Hoy',
          amountLabel: '+30',
          positive: true,
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.text('Recarga'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('+30'), findsOneWidget);
    await tester.tap(find.text('Recarga'));
    expect(taps, 1);
  });

  testWidgets('pack option shows coins, price and bonus and reports taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ManoPackOption(
          coinsLabel: '25 coins',
          priceLabel: '\$45.000',
          bonusLabel: '+3 gratis',
          selected: true,
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.text('25 coins'), findsOneWidget);
    expect(find.text('\$45.000'), findsOneWidget);
    expect(find.text('+3 gratis'), findsOneWidget);
    await tester.tap(find.text('25 coins'));
    expect(taps, 1);
  });

  testWidgets('photo gallery shows one tile per photo and no more', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const ManoPhotoGallery(urls: ['a', 'b', 'c'])),
    );
    expect(find.byType(Image), findsNWidgets(3));
  });

  testWidgets('photo gallery is empty without photos', (tester) async {
    await tester.pumpWidget(_host(const ManoPhotoGallery(urls: [])));
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('request card shows lead photo, category, zone and cost', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ManoRequestCard(
          clientName: 'Laura',
          clientPhotoUrl: '',
          title: 'Fuga',
          message: 'Gotea',
          scheduleLabel: 'hoy',
          amountLabel: '\$1',
          rateLabel: '/h',
          onTap: () {},
          categoryLabel: 'Plomería',
          zoneLabel: 'Laureles',
          photoUrl: 'https://example.com/a.jpg',
          photoCount: 2,
        ),
      ),
    );
    expect(find.text('Plomería · Laureles'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byKey(const Key('request-card-photo')), findsOneWidget);
  });
}
