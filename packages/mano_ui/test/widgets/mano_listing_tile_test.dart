import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

ManoListingTile _tile({double? rating = 4.8, VoidCallback? onTap}) =>
    ManoListingTile(
      title: 'Limpieza profunda de apartamento',
      photoUrl: 'https://example.com/listing.jpg',
      professionalName: 'Carlos Mendoza',
      priceLabel: 'Desde \$80.000',
      rating: rating,
      onTap: onTap ?? () {},
    );

void main() {
  group('the listing tile', () {
    testWidgets('shows title, professional, price and rating', (tester) async {
      await tester.pumpWidget(_host(SizedBox(width: 160, child: _tile())));

      expect(find.text('Limpieza profunda de apartamento'), findsOneWidget);
      expect(find.text('Carlos Mendoza'), findsOneWidget);
      expect(find.text('Desde \$80.000'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
    });

    testWidgets('a null rating hides the star', (tester) async {
      await tester.pumpWidget(
        _host(SizedBox(width: 160, child: _tile(rating: null))),
      );

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('the photo is square to the tile width', (tester) async {
      await tester.pumpWidget(_host(SizedBox(width: 160, child: _tile())));

      expect(tester.getSize(find.byType(AspectRatio)), const Size(160, 160));
    });

    testWidgets('fits a narrow tile at large text without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: _host(SizedBox(width: 140, child: _tile())),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(SizedBox(width: 160, child: _tile(onTap: () => taps++))),
      );

      await tester.tap(find.byType(ManoListingTile));
      expect(taps, 1);
    });
  });

  group('the listing rail', () {
    testWidgets('gives each child the item width and scrolls freely', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ManoListingRail(
            itemWidth: 150,
            children: [for (var i = 0; i < 6; i++) _tile()],
          ),
        ),
      );

      expect(tester.getSize(find.byType(ManoListingTile).first).width, 150);
      final scrollable = tester.widget<Scrollable>(find.byType(Scrollable));
      expect(scrollable.axisDirection, AxisDirection.right);
      expect(scrollable.physics, isNot(isA<PageScrollPhysics>()));
    });
  });
}
