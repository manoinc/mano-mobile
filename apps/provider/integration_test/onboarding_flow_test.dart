import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mano_provider/main.dart';
import 'package:mano_provider/shell/provider_nav_shell.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(ManoTextField)),
  matching: find.byType(TextField),
);

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

// Pumps so Continuar rebuilds enabled before the next tap.
Future<void> _type(WidgetTester tester, String label, String text) async {
  await tester.enterText(_field(label), text);
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a new professional signs up and enters the app', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          manoConfigProvider.overrideWithValue(testConfig),
          sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
        ],
        child: const ProviderApp(),
      ),
    );
    await tester.pumpAndSettle();

    await _tapText(tester, 'Crear cuenta profesional');

    await _type(tester, 'Nombre completo', 'Ana Gómez');
    await _tapText(tester, 'Continuar');
    await _type(tester, 'Celular', '300 123 4567');
    await _tapText(tester, 'Continuar');
    await _type(tester, 'Zona de cobertura', 'Chapinero');
    await _tapText(tester, 'Continuar');
    await _tapText(tester, 'Plomería');
    await _tapText(tester, 'Continuar');
    await _type(tester, 'Años de experiencia', '5');
    await _tapText(tester, 'Continuar');
    await _tapText(tester, 'Omitir');

    await _tapText(tester, 'Adjuntar');
    await _tapText(tester, 'Adjuntar');
    await _tapText(tester, 'Continuar');

    await _tapText(tester, 'Enviar a revisión');
    expect(find.text('Tu cuenta está en revisión'), findsOneWidget);

    await _tapText(tester, 'Explorar la app');
    expect(find.byType(ProviderNavShell), findsOneWidget);
  });
}
