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

  testWidgets('Enviar waits for a subject and a description', (tester) async {
    await _open(tester);

    await tester.scrollUntilVisible(
      find.text('Enviar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final enviar = tester.widget<ManoPrimaryButton>(
      find.ancestor(
        of: find.text('Enviar'),
        matching: find.byType(ManoPrimaryButton),
      ),
    );
    expect(enviar.onPressed, isNull);
  });

  testWidgets('filing a queja confirms it with its radicado', (tester) async {
    await _open(tester);

    await tester.ensureVisible(find.text('Queja'));
    await tester.tap(find.text('Queja'));
    await tester.enterText(_field('Asunto'), 'Cobro doble');
    await tester.enterText(
      _field('Cuéntanos qué pasó'),
      'Me cobraron dos veces la limpieza del sábado.',
    );
    await tester.pump();
    await _tapEnviar(tester);
    await tester.pumpAndSettle();

    expect(find.text('Recibimos tu queja'), findsOneWidget);
    expect(find.textContaining('MANO-'), findsOneWidget);
    expect(find.byType(ManoSupportForm), findsNothing);
  });
}
