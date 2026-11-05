import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_billing.dart';
import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

const _awaiting = Ok<CoinPurchase, DataFailure>(
  AwaitingApproval(paymentId: 'p1', coins: 35),
);

Future<ProviderContainer> _openRecharge(
  WidgetTester tester,
  ScriptedWallet wallet, [
  FakeLinks? links,
]) async {
  tester.view.physicalSize = const Size(1080, 4800);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final c = await pumpRouterAt(
    tester,
    '/wallet',
    overrides: billingOverrides(wallet, links ?? FakeLinks()),
    session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
  );
  await tester.tap(find.text('Recargar'));
  await tester.pumpAndSettle();
  return c;
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(ManoTextField)),
  matching: find.byType(TextField),
);

ManoPrimaryButton _pay(WidgetTester tester) => tester.widget(
  find.ancestor(
    of: find.textContaining('Pagar'),
    matching: find.byType(ManoPrimaryButton),
  ),
);

Future<void> _fillNequi(WidgetTester tester) async {
  await tester.tap(find.text('Nequi'));
  await tester.pumpAndSettle();
  await tester.enterText(_field('Celular de Nequi'), '300 123 4567');
  await tester.enterText(_field('Correo para el recibo'), 'andres@mano.test');
  await tester.pumpAndSettle();
}

Future<void> _acceptTerms(WidgetTester tester) async {
  await tester.tap(find.text('Acepto los términos de pago'));
  await tester.pumpAndSettle();
}

Future<void> _payAndSettleSheet(WidgetTester tester) async {
  await tester.tap(find.textContaining('Pagar'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('lists the packs billing sells, with the bonus', (tester) async {
    await _openRecharge(tester, ScriptedWallet(reply: _awaiting));

    expect(find.text('12 coins'), findsOneWidget);
    expect(find.text('30 coins'), findsOneWidget);
    expect(find.text('+5 gratis'), findsOneWidget);
    expect(find.text('Pagar · \$54.000'), findsOneWidget);
  });

  testWidgets('paying is blocked until the terms are accepted', (tester) async {
    await _openRecharge(tester, ScriptedWallet(reply: _awaiting));
    await _fillNequi(tester);

    expect(_pay(tester).onPressed, isNull);
    expect(find.text('Términos de la pasarela'), findsOneWidget);
    await _acceptTerms(tester);
    expect(_pay(tester).onPressed, isNotNull);
  });

  testWidgets('Nequi: approve in Nequi, then the coins land', (tester) async {
    final wallet = ScriptedWallet(reply: _awaiting, landsOnRead: 2);
    await _openRecharge(tester, wallet);
    await _fillNequi(tester);
    await _acceptTerms(tester);
    await _payAndSettleSheet(tester);

    expect(wallet.drafts.single.nequiPhone, '3001234567');
    expect(wallet.drafts.single.packId, 'pack-b');
    expect(find.text('Aprueba el pago en Nequi'), findsOneWidget);
    expect(find.text('Esperando a Nequi…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Aprueba el pago en Nequi'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('¡Listo! +35 coins'), findsOneWidget);
    expect(find.text('Ya tienes 45 Mano coins.'), findsOneWidget);
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(find.text('45'), findsOneWidget);
  });

  testWidgets('PSE: picks a bank, then opens the bank page', (tester) async {
    final links = FakeLinks();
    final wallet = ScriptedWallet(
      reply: const Ok(
        BankRedirect(paymentId: 'p1', coins: 35, url: 'https://bank.test/pay'),
      ),
    );
    final c = await _openRecharge(tester, wallet, links);
    await tester.tap(find.text('PSE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elige tu banco'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Banco Unión'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Número de documento'), '1020304050');
    await tester.enterText(_field('Correo para el recibo'), 'andres@mano.test');
    await _acceptTerms(tester);
    await _payAndSettleSheet(tester);

    expect(wallet.drafts.single.bankCode, '1022');
    expect(find.text('Termina el pago en tu banco'), findsOneWidget);
    await tester.tap(find.text('Ir a mi banco'));
    await tester.pump();
    expect(links.opened, [Uri.parse('https://bank.test/pay')]);

    c.read(coinPurchaseProvider.notifier).reset();
  });

  testWidgets('a purchase that never lands says it is still in process', (
    tester,
  ) async {
    await _openRecharge(tester, ScriptedWallet(reply: _awaiting));
    await _fillNequi(tester);
    await _acceptTerms(tester);
    await _payAndSettleSheet(tester);

    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();

    expect(find.text('Tu pago sigue en proceso'), findsOneWidget);
    expect(find.text('Revisar de nuevo'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('10'), findsOneWidget, reason: 'no coins pretended');
    expect(find.textContaining('recarga en proceso'), findsOneWidget);
  });

  testWidgets('a refusal says so and lets the provider try again', (
    tester,
  ) async {
    final wallet = ScriptedWallet(
      reply: const Err(DataRejected(reason: 'FailedPrecondition: declined')),
    );
    await _openRecharge(tester, wallet);
    await _fillNequi(tester);
    await _acceptTerms(tester);
    await _payAndSettleSheet(tester);
    await tester.pumpAndSettle();

    expect(find.text('No pudimos hacer la recarga'), findsOneWidget);
    expect(
      find.text('El pago fue rechazado. No te cobramos nada.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Intentar de nuevo'));
    await tester.pumpAndSettle();
    expect(find.text('Celular de Nequi'), findsOneWidget);
  });
}
