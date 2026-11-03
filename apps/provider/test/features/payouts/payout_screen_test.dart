import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';
import '../services/services_fakes.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String path = '/profile/payout',
}) async {
  tester.view.physicalSize = const Size(1080, 7200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final c = await pumpRouterAt(
    tester,
    path,
    overrides: [serviceCatalogProvider.overrideWithValue(FakeServiceCatalog())],
    session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
  );
  await tester.pumpAndSettle();
  return c;
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(ManoTextField)),
  matching: find.byType(TextField),
);

ManoPrimaryButton _primary(WidgetTester tester, String label) =>
    tester.widget(find.widgetWithText(ManoPrimaryButton, label));

Future<void> _next(WidgetTester tester, [String label = 'Continuar']) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _holder(WidgetTester tester) async {
  await tester.enterText(_field('Nombre del titular'), 'Andrés Castro');
  await tester.tap(find.text('CC'));
  await tester.enterText(_field('Número de documento'), '1020304050');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Cuenta para pagos on Perfil opens the method list', (
    tester,
  ) async {
    final c = await _pump(tester, path: '/profile');
    await tester.ensureVisible(find.text('Cuenta para pagos'));
    await tester.tap(find.text('Cuenta para pagos'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/profile/payout');
    expect(find.text('¿Dónde quieres recibir tus pagos?'), findsOneWidget);
    expect(find.text('Nequi'), findsOneWidget);
    expect(find.text('Cuenta bancaria'), findsOneWidget);
  });

  testWidgets('Nequi: phone, holder, then the masked account', (tester) async {
    final c = await _pump(tester);
    await tester.tap(find.text('Nequi'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Celular registrado en Nequi'), '200123');
    await tester.pumpAndSettle();
    expect(find.text('Un celular de 10 dígitos que empiece por 3.'), findsOne);
    expect(_primary(tester, 'Continuar').onPressed, isNull);

    await tester.enterText(
      _field('Celular registrado en Nequi'),
      '300 123 4567',
    );
    await tester.pumpAndSettle();
    await _next(tester);
    await _holder(tester);
    await _next(tester, 'Guardar cuenta');

    expect(find.text('Nequi'), findsOneWidget);
    expect(find.text('•••• 4567'), findsOneWidget);
    final account = await c.read(payoutAccountProvider.future);
    expect(account!.destination, const NequiDestination(phone: '3001234567'));
  });

  testWidgets('Bank: bank, type and number, holder', (tester) async {
    final c = await _pump(tester);
    await tester.tap(find.text('Cuenta bancaria'));
    await tester.pumpAndSettle();

    expect(_primary(tester, 'Continuar').onPressed, isNull);
    await tester.tap(find.text('Davivienda'));
    await tester.pumpAndSettle();
    await _next(tester);

    await tester.tap(find.text('Corriente'));
    await tester.enterText(_field('Número de cuenta'), '12a');
    await tester.pumpAndSettle();
    expect(find.text('Solo números, entre 6 y 20.'), findsOneWidget);
    await tester.enterText(_field('Número de cuenta'), '0012 3456 78');
    await tester.pumpAndSettle();
    await _next(tester);
    await _holder(tester);
    await _next(tester, 'Guardar cuenta');

    expect(find.text('Davivienda'), findsOneWidget);
    expect(find.text('Corriente · •••• 5678'), findsOneWidget);
    final account = await c.read(payoutAccountProvider.future);
    expect(
      account!.destination,
      const BankDestination(
        bankCode: '1051',
        accountType: BankAccountType.checking,
        accountNumber: '0012345678',
      ),
    );
  });

  testWidgets('back walks the questions, then leaves', (tester) async {
    final c = await _pump(tester, path: '/profile');
    await tester.ensureVisible(find.text('Cuenta para pagos'));
    await tester.tap(find.text('Cuenta para pagos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nequi'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();
    expect(find.text('¿Dónde quieres recibir tus pagos?'), findsOneWidget);

    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/profile');
  });

  testWidgets('a saved account can be removed', (tester) async {
    final c = await _pump(tester);
    await c
        .read(payoutActionsProvider.notifier)
        .register(
          const PayoutAccountDraft(
            method: PayoutMethod.nequi,
            phone: '3001234567',
            holderName: 'Andrés Castro',
            legalId: '1020304050',
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('•••• 4567'), findsOneWidget);

    await tester.tap(find.text('Eliminar cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(await c.read(payoutAccountProvider.future), isNull);
    expect(find.text('¿Dónde quieres recibir tus pagos?'), findsOneWidget);
  });

  testWidgets('Perfil shows the saved account masked', (tester) async {
    final c = await _pump(tester, path: '/profile');
    await c
        .read(payoutActionsProvider.notifier)
        .register(
          const PayoutAccountDraft(
            method: PayoutMethod.bank,
            bankCode: '1007',
            accountType: BankAccountType.savings,
            accountNumber: '12345678',
            holderName: 'Andrés Castro',
            legalId: '1020304050',
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('Bancolombia · •••• 5678'), findsOneWidget);
  });
}
