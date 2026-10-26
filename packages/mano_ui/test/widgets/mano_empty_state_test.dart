import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

Widget _darkHost(Widget child) => MaterialApp(
  theme: ManoTheme.dark(),
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

    testWidgets('without a CTA, shows no button', (tester) async {
      await tester.pumpWidget(
        _host(
          const ManoEmptyState(
            icon: Icons.work_outline,
            message: 'Aún no tienes proyectos',
          ),
        ),
      );

      expect(find.text('Aún no tienes proyectos'), findsOneWidget);
      expect(find.byType(ManoPrimaryButton), findsNothing);
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

    testWidgets(
      'renders the message in the dark-mode-appropriate color, not the hard-coded light one',
      (tester) async {
        await tester.pumpWidget(
          _darkHost(
            ManoEmptyState(
              icon: Icons.work_outline,
              message: 'Aún no tienes proyectos',
              ctaLabel: 'Explorar servicios',
              onCta: () {},
            ),
          ),
        );

        final message = tester.widget<Text>(
          find.text('Aún no tienes proyectos'),
        );
        final darkOnSurfaceVariant =
            ManoTheme.dark().colorScheme.onSurfaceVariant;

        expect(message.style?.color, isNot(ManoColors.muted));
        expect(message.style?.color, darkOnSurfaceVariant);
      },
    );
  });
}
