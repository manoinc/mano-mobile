import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/services/offer_editor_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';
import '../projects/projects_fakes.dart';
import 'services_fakes.dart';

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester,
    String location,
    FakeOfferManagement offers,
  ) {
    // Tall enough that the whole form is built, not lazily skipped.
    tester.view
      ..physicalSize = const Size(800, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Signed in: publishing needs an account (and a verified identity).
    return pumpRouterAt(
      tester,
      location,
      session: signedIn(),
      overrides: [
        offerManagementProvider.overrideWithValue(offers),
        serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
      ],
    );
  }

  FilledButton primary(WidgetTester tester, String label) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

  Finder field(String label) => find.descendant(
    of: find.widgetWithText(ManoTextField, label),
    matching: find.byType(TextField),
  );

  testWidgets('a new offer is published once a service and amount are set', (
    tester,
  ) async {
    final offers = FakeOfferManagement();
    final c = await pump(tester, '/profile/services/new', offers);

    expect(find.byType(OfferEditorScreen), findsOneWidget);
    expect(find.byType(ManoSearchField), findsOneWidget);
    expect(primary(tester, 'Publicar').onPressed, isNull);

    await tester.enterText(find.byType(ManoSearchField), 'fugas');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.text('Limpieza profunda'), findsNothing);
    await tester.tap(find.text('Reparación de fugas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Por hora'));
    await tester.pump();
    await tester.enterText(field('Valor por hora (COP)'), '50.000');
    await tester.enterText(field('Zona (opcional)'), 'Suba');
    await tester.pumpAndSettle();

    final preview = tester.widget<ManoPriceTag>(find.byType(ManoPriceTag));
    expect(preview.amountLabel, ManoFormat.cop(50000));
    expect(preview.rateLabel, '/hora');
    expect(primary(tester, 'Publicar').onPressed, isNotNull);

    await tester.ensureVisible(find.text('Publicar'));
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/profile/services');
    final card = tester.widget<ManoOfferCard>(find.byType(ManoOfferCard));
    expect(card.title, 'Reparación de fugas');
    expect(card.zone, 'Zona: Suba');
  });

  testWidgets('editing shows the service read-only and saves changes', (
    tester,
  ) async {
    final offers = FakeOfferManagement([offer('o1')]);
    final c = await pump(tester, '/profile/services/offer/o1', offers);

    expect(find.byType(ManoSearchField), findsNothing);
    expect(find.text('Limpieza profunda'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);

    await tester.enterText(field('Precio (COP)'), '150000');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/profile/services');
    final card = tester.widget<ManoOfferCard>(find.byType(ManoOfferCard));
    expect(card.amountLabel, ManoFormat.cop(150000));
  });

  testWidgets('pausing returns to the list showing it paused', (tester) async {
    final c = await pump(
      tester,
      '/profile/services/offer/o1',
      FakeOfferManagement([offer('o1')]),
    );
    await tester.ensureVisible(find.text('Pausar'));
    await tester.tap(find.text('Pausar'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/profile/services');
    expect(find.widgetWithText(ManoStatusChip, 'Pausada'), findsOneWidget);
  });

  testWidgets('a paused offer can be reactivated', (tester) async {
    await pump(
      tester,
      '/profile/services/offer/o1',
      FakeOfferManagement([offer('o1', status: OfferStatus.paused)]),
    );
    expect(find.text('Pausar'), findsNothing);
    await tester.ensureVisible(find.text('Reactivar'));
    await tester.tap(find.text('Reactivar'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ManoStatusChip, 'Activa'), findsOneWidget);
  });

  testWidgets('deleting asks first, then removes the offer', (tester) async {
    final c = await pump(
      tester,
      '/profile/services/offer/o1',
      FakeOfferManagement([offer('o1')]),
    );
    await tester.ensureVisible(find.text('Eliminar'));
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.byType(ManoDialogCard), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(ManoDialogCard),
        matching: find.text('Eliminar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(routerPath(c), '/profile/services');
    expect(find.text('Publicar mi primer servicio'), findsOneWidget);
  });

  testWidgets('a failed mutation shows a notice and stays', (tester) async {
    final offers = FakeOfferManagement([offer('o1')])
      ..fail = const DataUnavailable();
    final c = await pump(tester, '/profile/services/offer/o1', offers);

    await tester.ensureVisible(find.text('Pausar'));
    await tester.tap(find.text('Pausar'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/profile/services/offer/o1');
    expect(
      find.widgetWithText(ManoNotice, const DataUnavailable().message),
      findsOneWidget,
    );
  });

  testWidgets('Publicar clears the system navigation bar', (tester) async {
    // A 360 dp phone with a 48 dp gesture/3-button bar underneath.
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(bottom: 48)
      ..viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);
    await pumpRouterAt(
      tester,
      '/profile/services/new',
      overrides: [
        offerManagementProvider.overrideWithValue(FakeOfferManagement()),
        serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
      ],
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
    await tester.pumpAndSettle();

    final button = tester.getRect(
      find.widgetWithText(FilledButton, 'Publicar'),
    );
    expect(button.bottom, lessThanOrEqualTo(640 - 48));
  });

  testWidgets('an unknown offer shows an error with retry', (tester) async {
    await pump(tester, '/profile/services/offer/nope', FakeOfferManagement());
    expect(find.text('No pudimos cargar esta oferta'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
