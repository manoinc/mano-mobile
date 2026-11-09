import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';

const _config = BillingConfig(
  pollInterval: Duration(seconds: 1),
  settleTimeout: Duration(seconds: 10),
);

Finder _field(String label) => find.descendant(
  of: find.widgetWithText(ManoTextField, label),
  matching: find.byType(TextField),
);

ManoPrimaryButton _payButton(WidgetTester tester) =>
    tester.widget<ManoPrimaryButton>(find.byType(ManoPrimaryButton).last);

Future<ProviderContainer> _openCheckout(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  final c = await pumpRouterAt(
    tester,
    '/projects/job/job-5',
    overrides: [billingConfigProvider.overrideWithValue(_config), ...overrides],
  );
  await tester.tap(find.widgetWithText(ManoPrimaryButton, r'Pagar $120.000'));
  await tester.pumpAndSettle();
  return c;
}

// The form is a lazy list: scroll a field in before touching it.
Future<void> _reveal(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

Future<void> _type(WidgetTester tester, String label, String text) async {
  await _reveal(tester, _field(label));
  await tester.enterText(_field(label), text);
}

Future<void> _emailAndTerms(WidgetTester tester) async {
  await _type(tester, 'Correo para el recibo', 'ana@mano.test');
  await _reveal(tester, find.byType(ManoToggleRow));
  await tester.tap(find.byType(ManoToggleRow));
  await tester.pumpAndSettle();
}

Future<void> _fillNequi(WidgetTester tester) async {
  await tester.tap(find.text('Nequi'));
  await tester.pumpAndSettle();
  await _type(tester, 'Celular de Nequi', '300 123 4567');
  await _emailAndTerms(tester);
}

void main() {
  testWidgets('shows the job, the price and the ways to pay', (tester) async {
    await _openCheckout(tester);

    expect(find.text('Confirmar y pagar'), findsOneWidget);
    expect(find.text('Detalle del precio'), findsOneWidget);
    expect(find.text('Precio fijo'), findsOneWidget);
    expect(find.text('Total (COP)'), findsOneWidget);
    expect(find.text('Nequi'), findsOneWidget);
    expect(find.text('PSE'), findsOneWidget);
    expect(
      tester
          .widget<ManoMethodOption>(
            find.widgetWithText(ManoMethodOption, 'Tarjeta'),
          )
          .onTap,
      isNull,
    );
    expect(find.text('Próximamente'), findsOneWidget);
    expect(_payButton(tester).label, r'Pagar $120.000');
    expect(_payButton(tester).onPressed, isNull);
  });

  testWidgets('Nequi: approve, then the job shows Pagado', (tester) async {
    await _openCheckout(tester);
    await _fillNequi(tester);
    expect(_payButton(tester).onPressed, isNotNull);

    await tester.tap(find.text(r'Pagar $120.000'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Aprueba el pago en Nequi'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('¡Pago listo!'), findsOneWidget);

    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ManoStatusChip, 'Pagado'), findsOneWidget);
    expect(find.textContaining('Pagar'), findsNothing);
  });

  testWidgets('PSE sends the payer to their bank', (tester) async {
    final opened = <Uri>[];
    await _openCheckout(
      tester,
      overrides: [
        externalLinkOpenerProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
      ],
    );

    await tester.tap(find.text('PSE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elige tu banco'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bancolombia'));
    await tester.pumpAndSettle();
    await _type(tester, 'Número de documento', '1020304050');
    await _emailAndTerms(tester);

    await tester.tap(find.text(r'Pagar $120.000'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Termina el pago en tu banco'), findsOneWidget);
    await tester.tap(find.text('Ir a mi banco'));
    await tester.pump();
    expect(opened.single.toString(), 'https://mano.test/pse/job-5');

    // The mock settles on the next read; let it land so no timer is left.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('a refusal says so and Intentar de nuevo returns to the form', (
    tester,
  ) async {
    await _openCheckout(
      tester,
      overrides: [
        jobPaymentRepositoryProvider.overrideWithValue(_RefusingPayments()),
      ],
    );
    await _fillNequi(tester);

    await tester.tap(find.text(r'Pagar $120.000'));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cobrar el pago'), findsOneWidget);

    await tester.tap(find.text('Intentar de nuevo'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del precio'), findsOneWidget);
  });
}

final class _RefusingPayments implements JobPaymentRepository {
  @override
  Future<Result<JobPayment, DataFailure>> pay(JobPaymentDraft draft) async =>
      const Err(DataRejected(reason: 'declined'));

  @override
  Future<Result<JobPayment?, DataFailure>> payment(String jobId) async =>
      const Ok(null);

  @override
  Future<Result<List<CheckoutTerm>, DataFailure>> checkoutTerms() async =>
      const Ok([]);

  @override
  Future<Result<List<Bank>, DataFailure>> pseBanks() async => const Ok([]);
}
