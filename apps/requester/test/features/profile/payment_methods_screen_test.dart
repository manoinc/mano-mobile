import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
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
  return pumpRouterAt(
    tester,
    '/profile/payments',
    session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
  );
}

Future<void> _addVia(WidgetTester tester, String kind) async {
  await tester.tap(find.text('Agregar método de pago').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(kind));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('says payments are not live and starts empty', (tester) async {
    await _open(tester);

    expect(find.text('Métodos de pago'), findsOneWidget);
    expect(find.byType(ManoNotice), findsOneWidget);
    expect(find.byType(ManoEmptyState), findsOneWidget);
  });

  testWidgets('a card keeps only its brand and last four', (tester) async {
    final container = await _open(tester);

    await _addVia(tester, 'Tarjeta');
    await tester.enterText(_field('Número de tarjeta'), '4242 4242 4242 4242');
    await tester.enterText(_field('Vence (MM/AA)'), '12/39');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Visa •••• 4242'), findsOneWidget);
    expect(find.text('Predeterminado'), findsOneWidget);
    final saved = await container.read(savedPaymentMethodsProvider.future);
    expect(saved.single.last4, '4242');
  });

  testWidgets('a wrong card number is caught in the form', (tester) async {
    await _open(tester);

    await _addVia(tester, 'Tarjeta');
    await tester.enterText(_field('Número de tarjeta'), '4242 4242 4242 4241');
    await tester.enterText(_field('Vence (MM/AA)'), '12/39');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Revisa el número de la tarjeta.'), findsOneWidget);
  });

  testWidgets('adds Nequi, makes it default and deletes the card', (
    tester,
  ) async {
    final container = await _open(tester);
    await container
        .read(paymentMethodActionsProvider.notifier)
        .add(const NewCard(number: '4242424242424242', expiry: '12/39'));
    await tester.pumpAndSettle();

    await _addVia(tester, 'Nequi');
    await tester.enterText(_field('Celular de Nequi'), '300 123 4567');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Nequi •••• 4567'), findsOneWidget);

    await tester.tap(find.text('Nequi •••• 4567'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar como predeterminado'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Visa •••• 4242'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, eliminar'));
    await tester.pumpAndSettle();

    final saved = await container.read(savedPaymentMethodsProvider.future);
    expect(saved.single.kind, PaymentKind.nequi);
    expect(saved.single.isDefault, isTrue);
  });
}
