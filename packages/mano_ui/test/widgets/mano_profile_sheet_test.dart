import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: ManoTheme.light(),
    home: Scaffold(body: child),
  ),
);

void main() {
  group('ManoProfileSheet', () {
    testWidgets('shows the name, avatar and verified badge', (tester) async {
      await _pump(
        tester,
        const ManoProfileSheet(
          name: 'Ana Gómez',
          photoUrl: null,
          verified: true,
        ),
      );
      expect(find.text('Ana Gómez'), findsOneWidget);
      expect(find.byType(ManoAvatar), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('rating, facts and action are optional', (tester) async {
      await _pump(
        tester,
        const ManoProfileSheet(name: 'Luis', photoUrl: null, verified: false),
      );
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byIcon(Icons.verified), findsNothing);
      expect(find.byType(ManoPrimaryButton), findsNothing);
      expect(find.byKey(const Key('profile-fact')), findsNothing);
    });

    testWidgets('draws the rating and each fact as label and value', (
      tester,
    ) async {
      await _pump(
        tester,
        const ManoProfileSheet(
          name: 'Ana',
          photoUrl: null,
          verified: true,
          ratingLabel: '4,8 · 32 reseñas',
          facts: [
            ManoProfileFact(label: 'Zona', value: 'Chapinero'),
            ManoProfileFact(label: 'Rol', value: 'Profesional'),
          ],
        ),
      );
      expect(find.text('4,8 · 32 reseñas'), findsOneWidget);
      expect(find.byKey(const Key('profile-fact')), findsNWidgets(2));
      expect(find.text('Zona'), findsOneWidget);
      expect(find.text('Chapinero'), findsOneWidget);
    });

    testWidgets('the primary action fires its callback', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        ManoProfileSheet(
          name: 'Ana',
          photoUrl: null,
          verified: false,
          actionLabel: 'Ver perfil completo',
          onAction: () => taps++,
        ),
      );
      await tester.tap(find.text('Ver perfil completo'));
      expect(taps, 1);
    });
  });
}
