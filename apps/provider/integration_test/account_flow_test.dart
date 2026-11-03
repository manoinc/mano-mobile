import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mano_provider/main.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../test/features/services/services_fakes.dart';
import '../test/support/fake_media.dart';
import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(ManoTextField)),
  matching: find.byType(TextField),
);

Future<void> _openFromPerfil(WidgetTester tester, String row) async {
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text(row),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
  await tester.pumpAndSettle();
  await tester.tap(find.text(row));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, String text) async {
  // The keyboard shrinks the form on a phone, and lazy lists build late.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMarketplaceProvider.overrideWithValue(true),
          manoConfigProvider.overrideWithValue(testConfig),
          sessionRepositoryProvider.overrideWithValue(
            FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
          ),
          serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
          ...fakeMediaOverrides(),
        ],
        child: const ProviderApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a provider edits the profile and Perfil shows it', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cambiar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir de la galería'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Nombre para mostrar'), 'Andrés C.');
    await tester.pumpAndSettle();
    await _tapVisible(tester, 'Electricidad');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Andrés C.'), findsOneWidget);
  });

  testWidgets('a provider files a PQRS and gets a radicado', (tester) async {
    await launch(tester);
    await _openFromPerfil(tester, 'Ayuda y PQRS');

    await tester.tap(find.text('Queja'));
    await tester.enterText(find.byKey(const Key('support-subject')), 'Demora');
    await tester.enterText(
      find.byKey(const Key('support-description')),
      'El cliente no confirmó el trabajo terminado.',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Recibimos tu queja'), findsOneWidget);
    expect(find.textContaining('MANO-'), findsOneWidget);
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
  });

  testWidgets('a provider registers a Nequi payout account', (tester) async {
    await launch(tester);
    await _openFromPerfil(tester, 'Cuenta para pagos');

    await tester.tap(find.text('Nequi'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Celular registrado en Nequi'), '3001234567');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Nombre del titular'), 'Andrés Castro');
    await tester.pumpAndSettle();
    await tester.enterText(_field('Número de documento'), '1020304050');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('•••• 4567'), findsOneWidget);
  });
}
