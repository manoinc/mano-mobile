import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('a person preview', () {
    testWidgets('shows who they are and what they have done', (tester) async {
      await tester.pumpWidget(
        _host(
          const ManoPersonRow(
            avatar: ManoInitialsAvatar(initials: 'CR'),
            name: 'Cristian R.',
            detail: '147 trabajos de reparación',
            rating: 5,
            ratingLabel: '4,9 (147)',
          ),
        ),
      );

      expect(find.text('Cristian R.'), findsOneWidget);
      expect(find.text('147 trabajos de reparación'), findsOneWidget);
      expect(find.text('4,9 (147)'), findsOneWidget);
      expect(find.text('CR'), findsOneWidget);
    });

    testWidgets('draws five stars and fills them to the rating', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const ManoPersonRow(
            avatar: ManoInitialsAvatar(initials: 'SC'),
            name: 'Sara C.',
            detail: '98 armados de muebles',
            rating: 3.5,
            ratingLabel: '3,5 (98)',
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    });

    testWidgets('keeps stars off the one hot colour', (tester) async {
      // Flame is reserved for the single primary action on a screen; a rating
      // is secondary emphasis, which is what clay is for.
      await tester.pumpWidget(
        _host(
          const ManoPersonRow(
            avatar: ManoInitialsAvatar(initials: 'SC'),
            name: 'Sara C.',
            detail: '98 trabajos',
            rating: 5,
            ratingLabel: '5,0 (98)',
          ),
        ),
      );

      final star = tester.widget<Icon>(find.byIcon(Icons.star_rounded).first);
      expect(star.color, isNot(ManoColors.flame));
    });
  });

  group('a booking preview', () {
    testWidgets('shows the job, when it is, and what it costs', (tester) async {
      await tester.pumpWidget(
        _host(
          const ManoBookingCard(
            avatar: ManoInitialsAvatar(initials: 'TR'),
            name: 'Tatiana R.',
            task: 'Instalación de TV',
            when: 'Jue 24 de oct · 10:00 a.m.',
            price: '\$85.000',
          ),
        ),
      );

      expect(find.text('Tatiana R.'), findsOneWidget);
      expect(find.text('Instalación de TV'), findsOneWidget);
      expect(find.text('Jue 24 de oct · 10:00 a.m.'), findsOneWidget);
      expect(find.text('\$85.000'), findsOneWidget);
    });

    testWidgets('survives a narrow phone at large text', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ManoTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const Scaffold(
              body: ManoBookingCard(
                avatar: ManoInitialsAvatar(initials: 'TR'),
                name: 'Tatiana Restrepo Gómez',
                task: 'Instalación de televisor en pared de concreto',
                when: 'Jueves 24 de octubre · 10:00 a.m.',
                price: '\$85.000',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
