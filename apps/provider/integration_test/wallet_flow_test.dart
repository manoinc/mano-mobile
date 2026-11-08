import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mano_provider/main.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../test/features/services/services_fakes.dart';
import '../test/support/fake_billing.dart';
import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(ManoTextField)),
  matching: find.byType(TextField),
);

Future<void> _tapVisible(WidgetTester tester, String text) async {
  // The keyboard covers the sheet's lower half on a phone.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

// The waiting state spins, so no settling after the tap.
Future<void> _pay(WidgetTester tester, String label) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pump(const Duration(milliseconds: 500));
}

// Real time passes on a device: pump until [text] shows or [limit] runs out.
Future<void> _waitFor(
  WidgetTester tester,
  String text, {
  Duration limit = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(limit);
  while (find.text(text).evaluate().isEmpty && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> launch(
    WidgetTester tester, [
    List<Override> extra = const [],
  ]) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMarketplaceProvider.overrideWithValue(true),
          manoConfigProvider.overrideWithValue(testConfig),
          sessionRepositoryProvider.overrideWithValue(
            FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
          ),
          serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
          billingConfigProvider.overrideWithValue(
            const BillingConfig(
              pollInterval: Duration(seconds: 1),
              settleTimeout: Duration(seconds: 20),
            ),
          ),
          ...extra,
        ],
        child: const ProviderApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Billetera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recargar'));
    await tester.pumpAndSettle();
  }

  Future<void> payWithNequi(WidgetTester tester) async {
    await tester.tap(find.text('Nequi'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Celular de Nequi'), '3001234567');
    await tester.pumpAndSettle();
    await tester.enterText(_field('Correo para el recibo'), 'andres@mano.test');
    await tester.pumpAndSettle();
    await _tapVisible(tester, 'Acepto los términos de pago');
    await _pay(tester, 'Pagar · \$50.000');
  }

  testWidgets('a provider recharges by Nequi and the coins land', (
    tester,
  ) async {
    await launch(tester);
    expect(find.text('Recargar coins'), findsOneWidget);
    await payWithNequi(tester);

    await _waitFor(tester, '¡Listo! +55 coins');
    expect(find.text('¡Listo! +55 coins'), findsOneWidget);
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(find.text('80'), findsOneWidget);
  });

  testWidgets('a provider pays by PSE and is sent to the bank', (tester) async {
    final links = FakeLinks();
    await launch(tester, [
      externalLinkOpenerProvider.overrideWithValue(links.open),
      walletRepositoryProvider.overrideWithValue(
        ScriptedWallet(
          reply: const Ok(
            BankRedirect(
              paymentId: 'p1',
              coins: 35,
              url: 'https://pse.mano.test/p1',
            ),
          ),
        ),
      ),
    ]);
    await tester.tap(find.text('PSE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elige tu banco'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Banco Unión'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Número de documento'), '1020304050');
    await tester.pumpAndSettle();
    await tester.enterText(_field('Correo para el recibo'), 'andres@mano.test');
    await tester.pumpAndSettle();
    await _tapVisible(tester, 'Acepto los términos de pago');
    await _pay(tester, 'Pagar · \$54.000');

    await _waitFor(tester, 'Ir a mi banco', limit: const Duration(seconds: 3));
    await tester.tap(find.text('Ir a mi banco'));
    await tester.pump();
    expect(links.opened, [Uri.parse('https://pse.mano.test/p1')]);
    await tester.tap(find.text('Cerrar'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('recarga en proceso'), findsOneWidget);
  });
}
