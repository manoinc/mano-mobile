import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('the empty state', () {
    testWidgets('renders the message, the icon and the CTA label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ManoEmptyState(
            icon: Icons.work_outline,
            message: 'Aún no tienes proyectos',
            ctaLabel: 'Explorar servicios',
            onCta: () {},
          ),
        ),
      );

      expect(find.text('Aún no tienes proyectos'), findsOneWidget);
      expect(find.text('Explorar servicios'), findsOneWidget);
      expect(find.byIcon(Icons.work_outline), findsOneWidget);
    });

    testWidgets('fires onCta once when the CTA is tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ManoEmptyState(
            icon: Icons.work_outline,
            message: 'Aún no tienes proyectos',
            ctaLabel: 'Explorar servicios',
            onCta: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('Explorar servicios'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });
}
