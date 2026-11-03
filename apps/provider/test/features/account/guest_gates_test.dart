import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';
import '../services/services_fakes.dart';

/// Guests keep the whole shell; account-only actions ask them to sign in.
Future<ProviderContainer> _asGuest(
  WidgetTester tester,
  String path, {
  List<Override> overrides = const [],
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = await pumpRouterAt(tester, path, overrides: overrides);
  await container.read(sessionProvider.future);
  container.read(sessionProvider.notifier).browseAsGuest();
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void _expectSheet(String reason) {
  expect(find.byType(ManoAccountNeededSheet), findsOneWidget);
  expect(find.text(reason), findsOneWidget);
}

void main() {
  testWidgets('accepting a request asks a guest to sign in', (tester) async {
    await _asGuest(tester, '/home');

    await _tap(tester, find.text('Aceptar · 2 coins').first);

    _expectSheet('Inicia sesión para responder solicitudes.');
  });

  testWidgets('rejecting a request asks a guest to sign in', (tester) async {
    await _asGuest(tester, '/home');

    await _tap(tester, find.text('Rechazar').first);

    _expectSheet('Inicia sesión para responder solicitudes.');
  });

  testWidgets('a new offer asks a guest to sign in', (tester) async {
    final container = await _asGuest(
      tester,
      '/profile/services',
      overrides: [
        offerManagementProvider.overrideWithValue(FakeOfferManagement([])),
        serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
      ],
    );

    await _tap(tester, find.text('Nueva oferta'));

    _expectSheet('Inicia sesión para publicar y editar tus servicios.');
    expect(routerPath(container), '/profile/services');
  });

  testWidgets('adding weekly hours asks a guest to sign in', (tester) async {
    await _asGuest(tester, '/agenda/availability');

    await _tap(tester, find.text('Agregar horario'));

    _expectSheet('Inicia sesión para manejar tu disponibilidad.');
  });

  testWidgets('blocking dates asks a guest to sign in', (tester) async {
    await _asGuest(tester, '/agenda/availability');

    await _tap(tester, find.text('Bloquear fechas'));

    _expectSheet('Inicia sesión para manejar tu disponibilidad.');
  });

  testWidgets('sending a message asks a guest to sign in', (tester) async {
    await _asGuest(tester, '/inbox/conv-1');

    await tester.enterText(find.byType(TextField), 'Hola');
    await tester.tap(find.byKey(const Key('mano-composer-send')));
    await tester.pumpAndSettle();

    _expectSheet('Inicia sesión para escribirle a tus clientes.');
    expect(find.text('Hola'), findsNothing, reason: 'nothing was sent');
  });

  testWidgets('attaching a photo asks a guest to sign in', (tester) async {
    await _asGuest(tester, '/inbox/conv-1');

    await tester.tap(find.byKey(const Key('mano-composer-attach')));
    await tester.pumpAndSettle();

    _expectSheet('Inicia sesión para escribirle a tus clientes.');
    expect(find.byType(ManoMediaSourceSheet), findsNothing);
  });

  testWidgets('Iniciar sesión takes the guest back to the door', (
    tester,
  ) async {
    final container = await _asGuest(tester, '/home');
    await _tap(tester, find.text('Rechazar').first);

    await _tap(
      tester,
      find.descendant(
        of: find.byType(ManoAccountNeededSheet),
        matching: find.text('Iniciar sesión'),
      ),
    );

    expect(container.read(sessionProvider).value, isA<SignedOut>());
  });
}
