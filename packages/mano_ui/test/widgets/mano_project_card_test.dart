import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('the project card', () {
    testWidgets(
      'renders title, professional name, status, schedule and price',
      (tester) async {
        await tester.pumpWidget(
          _host(
            ManoProjectCard(
              title: 'Limpieza profunda de hogar',
              professionalName: 'Ana Torres',
              professionalPhotoUrl: 'https://example.com/ana.jpg',
              statusLabel: 'Programado',
              statusTone: ManoStatusTone.info,
              scheduledLabel: 'Mar 12, 3:00 p.m.',
              priceLabel: '\$80.000 COP',
              onTap: () {},
            ),
          ),
        );

        expect(find.text('Limpieza profunda de hogar'), findsOneWidget);
        expect(find.text('Ana Torres'), findsOneWidget);
        expect(find.text('Programado'), findsOneWidget);
        expect(find.text('Mar 12, 3:00 p.m.'), findsOneWidget);
        expect(find.text('\$80.000 COP'), findsOneWidget);
      },
    );

    testWidgets('fires onTap once when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ManoProjectCard(
            title: 'Limpieza profunda de hogar',
            professionalName: 'Ana Torres',
            professionalPhotoUrl: 'https://example.com/ana.jpg',
            statusLabel: 'Programado',
            statusTone: ManoStatusTone.info,
            scheduledLabel: 'Mar 12, 3:00 p.m.',
            priceLabel: '\$80.000 COP',
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(ManoProjectCard));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('gives different status tones visibly different badge colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ManoProjectCard(
            title: 'Limpieza profunda de hogar',
            professionalName: 'Ana Torres',
            professionalPhotoUrl: 'https://example.com/ana.jpg',
            statusLabel: 'Completado',
            statusTone: ManoStatusTone.success,
            scheduledLabel: 'Mar 12, 3:00 p.m.',
            priceLabel: '\$80.000 COP',
            onTap: () {},
          ),
        ),
      );
      final successBadge = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const Key('mano-project-card-status-badge')),
          matching: find.byType(Container),
        ),
      );
      final successColor = (successBadge.decoration! as BoxDecoration).color;

      await tester.pumpWidget(
        _host(
          ManoProjectCard(
            title: 'Limpieza profunda de hogar',
            professionalName: 'Ana Torres',
            professionalPhotoUrl: 'https://example.com/ana.jpg',
            statusLabel: 'Reprogramar',
            statusTone: ManoStatusTone.warning,
            scheduledLabel: 'Mar 12, 3:00 p.m.',
            priceLabel: '\$80.000 COP',
            onTap: () {},
          ),
        ),
      );
      final warningBadge = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const Key('mano-project-card-status-badge')),
          matching: find.byType(Container),
        ),
      );
      final warningColor = (warningBadge.decoration! as BoxDecoration).color;

      expect(successColor, isNot(warningColor));
    });
  });
}
