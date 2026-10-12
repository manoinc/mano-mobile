import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mano_provider/main.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../test/features/services/services_fakes.dart';
import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a provider publishes an offer and pauses it', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          manoConfigProvider.overrideWithValue(testConfig),
          sessionRepositoryProvider.overrideWithValue(
            FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
          ),
          serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
          offerManagementProvider.overrideWithValue(FakeOfferManagement()),
        ],
        child: const ProviderApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Mis servicios'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reparación de fugas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Por hora'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Valor por hora (COP)'), '50000');
    await tester.enterText(_field('Zona (opcional)'), 'Suba');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Publicar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    final card = find.widgetWithText(ManoOfferCard, 'Reparación de fugas');
    expect(card, findsOneWidget);
    expect(find.widgetWithText(ManoStatusChip, 'Activa'), findsOneWidget);

    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Pausar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Pausar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ManoStatusChip, 'Pausada'), findsOneWidget);
  });
}

Finder _field(String label) => find.descendant(
  of: find.widgetWithText(ManoTextField, label),
  matching: find.byType(TextField),
);
