import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';

Finder _field(String label) => find.descendant(
  of: find.widgetWithText(ManoTextField, label),
  matching: find.byType(TextField),
);

Future<ProviderContainer> _open(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return pumpRouterAt(tester, '/profile/support');
}

// Scrolls past the shell's centre button, which overlaps the list's last pixels.
Future<void> _tapEnviar(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Enviar'));
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Enviar'));
}

void main() {
  testWidgets('answers common questions in place', (tester) async {
    await _open(tester);

    expect(find.text('Atención al cliente'), findsOneWidget);
    await tester.tap(find.text('¿Cómo cancelo un trabajo?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Actividad'), findsWidgets);
  });

  testWidgets('a thin message is sent back with what is missing', (
    tester,
  ) async {
    await _open(tester);

    await _tapEnviar(tester);
    await tester.pumpAndSettle();

    expect(find.text('Escribe el asunto.'), findsOneWidget);
    expect(find.text('Cuéntanos qué pasó.'), findsOneWidget);
  });

  testWidgets('filing a ticket confirms it with its radicado', (tester) async {
    await _open(tester);

    await tester.enterText(_field('Asunto'), 'Cobro doble');
    await tester.enterText(
      _field('Cuéntanos qué pasó'),
      'Me cobraron dos veces la limpieza del sábado.',
    );
    await _tapEnviar(tester);
    await tester.pumpAndSettle();

    expect(find.text('Recibimos tu mensaje'), findsOneWidget);
    expect(find.textContaining('PQR-'), findsOneWidget);
    expect(find.byType(ManoSupportForm), findsNothing);
  });
}
