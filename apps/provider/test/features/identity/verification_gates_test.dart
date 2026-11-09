import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_identity.dart';
import '../../support/pump_app.dart';
import '../projects/projects_fakes.dart';
import '../services/services_fakes.dart';

const _title = 'Verifica tu identidad para continuar';

/// A signed-in pro whose identity check has not come back approved.
Future<ProviderContainer> _unverified(
  WidgetTester tester,
  String path, {
  List<Override> overrides = const [],
  IdentityCheckStatus? status,
}) async {
  tester.view
    ..physicalSize = const Size(1600, 2400)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = await pumpRouterAt(
    tester,
    path,
    session: signedIn(),
    identity: FakeIdentityVerification(status),
    overrides: overrides,
  );
  await c.read(sessionProvider.future);
  await tester.pumpAndSettle();
  return c;
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

List<Override> _offers(FakeOfferManagement offers) => [
  offerManagementProvider.overrideWithValue(offers),
  serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
];

void main() {
  testWidgets('accepting a request asks to verify first', (tester) async {
    await _unverified(tester, '/home');

    await _tap(tester, find.text('Aceptar').first);

    expect(find.text(_title), findsOneWidget);
  });

  testWidgets('rejecting a request asks to verify first', (tester) async {
    await _unverified(tester, '/home');

    await _tap(tester, find.text('Rechazar').first);

    expect(find.text(_title), findsOneWidget);
  });

  testWidgets('quoting a project asks to verify first', (tester) async {
    await _unverified(tester, '/home/project/project-5');

    await _tap(tester, find.text('Cotizar gratis'));

    expect(find.text(_title), findsOneWidget);
    expect(find.text('Enviar cotización'), findsNothing);
  });

  testWidgets('buying a lead asks to verify first', (tester) async {
    final chosen = Quote(
      id: 'quote-z',
      projectId: 'project-z',
      projectTitle: 'Cambiar la iluminación',
      worker: const Party(id: 'w', displayName: 'Ana', photoUrl: ''),
      amountCop: 580000,
      status: QuoteStatus.selected,
      createdAt: DateTime(2026, 11, 3),
      projectCategory: ServiceCategories.electrical,
    );
    await _unverified(
      tester,
      '/home/project/project-z',
      overrides: [
        leadRepositoryProvider.overrideWithValue(FakeLeads(quotes: [chosen])),
      ],
    );

    await _tap(tester, find.text('Comprar contacto'));

    expect(find.text(_title), findsOneWidget);
    expect(find.byKey(const Key('lead-purchase-sheet')), findsNothing);
  });

  testWidgets('reactivating an offer asks to verify first', (tester) async {
    final offers = FakeOfferManagement([
      offer('o1', status: OfferStatus.paused),
    ]);
    await _unverified(
      tester,
      '/profile/services/offer/o1',
      overrides: _offers(offers),
    );

    await _tap(tester, find.text('Reactivar'));

    expect(find.text(_title), findsOneWidget);
    expect(find.text('Pausar'), findsNothing);
  });

  testWidgets('a pending check still asks to verify', (tester) async {
    await _unverified(tester, '/home', status: const IdentityCheckPending());

    await _tap(tester, find.text('Aceptar').first);

    expect(find.text(_title), findsOneWidget);
  });

  testWidgets('Verificar ahora opens the identity photos', (tester) async {
    final c = await _unverified(tester, '/home');
    await _tap(tester, find.text('Aceptar').first);

    await _tap(tester, find.text('Verificar ahora'));

    expect(routerPath(c), '/profile/identity');
    expect(find.byType(ManoTipList), findsOneWidget);
  });

  testWidgets('Ahora no closes the sheet and does nothing', (tester) async {
    final c = await _unverified(tester, '/home');
    await _tap(tester, find.text('Aceptar').first);

    await _tap(tester, find.text('Ahora no'));

    expect(find.text(_title), findsNothing);
    expect(routerPath(c), '/home');
  });
}
