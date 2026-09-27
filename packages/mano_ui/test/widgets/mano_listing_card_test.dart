import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('the listing card', () {
    testWidgets('renders title, professional name and price label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ManoListingCard(
            title: 'Limpieza profunda de hogar',
            photoUrl: 'https://example.com/listing.jpg',
            professionalName: 'Ana Torres',
            professionalPhotoUrl: 'https://example.com/ana.jpg',
            priceLabel: 'Desde \$80.000 COP',
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Limpieza profunda de hogar'), findsOneWidget);
      expect(find.text('Ana Torres'), findsOneWidget);
      expect(find.text('Desde \$80.000 COP'), findsOneWidget);
    });

    testWidgets('fires onTap once when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ManoListingCard(
            title: 'Limpieza profunda de hogar',
            photoUrl: 'https://example.com/listing.jpg',
            professionalName: 'Ana Torres',
            professionalPhotoUrl: 'https://example.com/ana.jpg',
            priceLabel: 'Desde \$80.000 COP',
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(ManoListingCard));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('renders no rating element when rating is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ManoListingCard(
            title: 'Limpieza profunda de hogar',
            photoUrl: 'https://example.com/listing.jpg',
            professionalName: 'Ana Torres',
            professionalPhotoUrl: 'https://example.com/ana.jpg',
            priceLabel: 'Desde \$80.000 COP',
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('4.8'), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('renders a rating element when rating is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ManoListingCard(
            title: 'Limpieza profunda de hogar',
            photoUrl: 'https://example.com/listing.jpg',
            professionalName: 'Ana Torres',
            professionalPhotoUrl: 'https://example.com/ana.jpg',
            priceLabel: 'Desde \$80.000 COP',
            rating: 4.8,
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('4.8'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}
