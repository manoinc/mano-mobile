import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('waiting shows its title, message and a live waiting line', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ManoPaymentStatus(
          icon: Icons.phone_iphone,
          title: 'Aprueba el pago en Nequi',
          message: 'Te enviamos una notificación.',
          waitingLabel: 'Esperando a Nequi…',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Aprueba el pago en Nequi'), findsOneWidget);
    expect(find.text('Te enviamos una notificación.'), findsOneWidget);
    expect(find.text('Esperando a Nequi…'), findsOneWidget);
    expect(find.byType(ManoLoader), findsOneWidget);
  });

  testWidgets('done and failed show no waiting line', (tester) async {
    for (final tone in [ManoPaymentTone.done, ManoPaymentTone.failed]) {
      await tester.pumpWidget(
        _host(
          ManoPaymentStatus(
            icon: Icons.check,
            title: 'Listo',
            message: '+28 coins',
            tone: tone,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Listo'), findsOneWidget);
      expect(find.byType(ManoLoader), findsNothing);
    }
  });

  testWidgets('the failed tone draws its mark in the error colour', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ManoPaymentStatus(
          icon: Icons.error_outline,
          title: 'No se pudo',
          message: 'Intenta de nuevo.',
          tone: ManoPaymentTone.failed,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
    final scheme = ManoTheme.light().colorScheme;
    expect(icon.color, scheme.error);
  });

  testWidgets('a long waiting line wraps on a narrow phone', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 240,
          child: ManoPaymentStatus(
            icon: Icons.account_balance_outlined,
            title: 'Termina el pago en tu banco',
            message: 'Vuelve a Mano cuando pagues.',
            waitingLabel: 'Esperando confirmación del banco por PSE…',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });
}
