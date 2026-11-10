import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/profile/payment_brand_mark.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

Finder _field(String label) => find.descendant(
  of: find.widgetWithText(ManoTextField, label),
  matching: find.byType(TextField),
);

Finder _row(String title) => find.widgetWithText(ManoMethodRow, title);

// No saved methods, to check the screen without any rows.
class _NoMethods extends Fake implements PaymentMethods {
  @override
  Future<List<PaymentMethod>> list() async => const [];
}

Future<ProviderContainer> _open(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return pumpRouterAt(
    tester,
    '/profile/payments',
    session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    overrides: overrides,
  );
}

Future<void> _addVia(WidgetTester tester, String kind) async {
  await tester.tap(find.text('Agregar método de pago').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(kind));
  await tester.pumpAndSettle();
}

Future<void> _edit(WidgetTester tester, String title) async {
  await tester.tap(
    find.descendant(of: _row(title), matching: find.text('Editar')),
  );
  await tester.pumpAndSettle();
}

Future<void> _reveal(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Más información'), 200);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists the saved methods Airbnb-style', (tester) async {
    await _open(tester);

    expect(find.text('Métodos de pago'), findsOneWidget);
    expect(
      find.text(
        'Agrega y administra tus métodos de pago con nuestro sistema de '
        'pago seguro.',
      ),
      findsOneWidget,
    );
    expect(find.byType(ManoMethodRow), findsNWidgets(2));
    expect(
      find.descendant(
        of: _row('Mastercard 8341'),
        matching: find.text('Vence: 05/2033 · Predeterminado'),
      ),
      findsOneWidget,
    );
    expect(find.text('Predeterminado'), findsNothing);
    expect(
      find.descendant(
        of: _row('Nequi 4567'),
        matching: find.text('Billetera Nequi'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _row('Mastercard 8341'),
        matching: find.byType(PaymentBrandMark),
      ),
      findsOneWidget,
    );
    expect(find.text('Nequi 4567'), findsOneWidget);
    expect(find.text('Editar'), findsNWidgets(2));
  });

  testWidgets('a compact ink add button and the Mano promise', (tester) async {
    final c = await _open(tester);

    final add = tester.widget<ManoPrimaryButton>(
      find.widgetWithText(ManoPrimaryButton, 'Agregar método de pago'),
    );
    expect(add.tone, ManoPrimaryTone.ink);
    expect(add.compact, isTrue);
    expect(find.text('Paga siempre a través de Mano'), findsOneWidget);

    await _reveal(tester);
    await tester.tapOnText(find.textRange.ofSubstring('Términos de pago'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/profile/support');
  });

  testWidgets('Más información opens support', (tester) async {
    final c = await _open(tester);

    await _reveal(tester);
    await tester.tap(find.text('Más información'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/profile/support');
  });

  testWidgets('with nothing saved it shows only the add button and card', (
    tester,
  ) async {
    await _open(
      tester,
      overrides: [paymentMethodsProvider.overrideWithValue(_NoMethods())],
    );

    expect(find.byType(ManoMethodRow), findsNothing);
    expect(find.text('Agregar método de pago'), findsOneWidget);
    expect(find.text('Paga siempre a través de Mano'), findsOneWidget);
  });

  testWidgets('a card keeps only its brand, last four and expiry', (
    tester,
  ) async {
    final container = await _open(tester);

    await _addVia(tester, 'Tarjeta');
    await tester.enterText(_field('Número de tarjeta'), '4242 4242 4242 4242');
    await tester.enterText(_field('Vence (MM/AA)'), '12/39');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: _row('Visa 4242'),
        matching: find.text('Vence: 12/2039'),
      ),
      findsOneWidget,
    );
    final saved = await container.read(savedPaymentMethodsProvider.future);
    expect(saved.last.last4, '4242');
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

    await _addVia(tester, 'Nequi');
    await tester.enterText(_field('Celular de Nequi'), '300 765 4321');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Nequi 4321'), findsOneWidget);

    await _edit(tester, 'Nequi 4321');
    await tester.tap(find.text('Usar como predeterminado'));
    await tester.pumpAndSettle();

    await _edit(tester, 'Mastercard 8341');
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, eliminar'));
    await tester.pumpAndSettle();

    final saved = await container.read(savedPaymentMethodsProvider.future);
    expect(saved.map((m) => m.kind), everyElement(PaymentKind.nequi));
    expect(saved.first.last4, '4321');
    expect(saved.first.isDefault, isTrue);
    expect(find.text('Mastercard 8341'), findsNothing);
  });
}
