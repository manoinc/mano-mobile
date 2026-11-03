import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mano_requester/main.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../test/support/fake_media.dart';
import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

Finder _field(String label) => find.descendant(
  of: find.widgetWithText(ManoTextField, label),
  matching: find.byType(TextField),
);

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton)); // locale-proof, unlike pageBack()
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a requester fills in Perfil and sees it on Inicio', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMarketplaceProvider.overrideWithValue(true),
          manoConfigProvider.overrideWithValue(testConfig),
          sessionRepositoryProvider.overrideWithValue(
            FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
          ),
          mediaPickerProvider.overrideWithValue(FakeMediaPicker()),
        ],
        child: const RequesterApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    // Información personal, with a new photo.
    await tester.tap(find.text('Información personal'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ManoAvatarEditor));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir de la galería'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Nombre completo'), 'Ana Rojas');
    await tester.enterText(_field('Celular'), '300 123 4567');
    await tester.enterText(_field('Correo'), 'ana@mano.co');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Rojas'), findsOneWidget);

    // Direcciones guardadas.
    await tester.tap(find.text('Direcciones guardadas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar dirección'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Nombre'), 'Casa');
    await tester.enterText(_field('Dirección'), 'Calle 45 # 12-30');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Predeterminada'), findsOneWidget);
    await _back(tester);

    // Métodos de pago.
    await tester.tap(find.text('Métodos de pago'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar método de pago').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nequi'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Celular de Nequi'), '300 123 4567');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Nequi •••• 4567'), findsOneWidget);
    await _back(tester);

    // Historial de pedidos.
    await tester.tap(find.text('Historial de pedidos'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoProjectCard), findsWidgets);
    await _back(tester);

    // Atención al cliente.
    await tester.tap(find.text('Atención al cliente'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Asunto'), 'Cobro doble');
    await tester.enterText(
      _field('Cuéntanos qué pasó'),
      'Me cobraron dos veces la limpieza del sábado.',
    );
    // The keyboard shrinks the list on a phone; close it before scrolling.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Enviar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Enviar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('MANO-'), findsOneWidget);
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    // The default address reaches the Inicio pill.
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Casa · Calle 45 # 12-30'), findsOneWidget);
  });
}
