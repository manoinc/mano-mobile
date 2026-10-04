import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';
import 'fake_service_catalog.dart';

final class _BrokenCatalog extends FakeServiceCatalog {
  bool broken = true;

  @override
  Future<JobService?> service(String id) async {
    // An Error, not an Exception, so Riverpod surfaces it without auto-retrying.
    if (broken) throw StateError('down');
    return super.service(id);
  }
}

void main() {
  testWidgets('shows title, category label and the full description', (
    tester,
  ) async {
    await pumpRouterAt(
      tester,
      '/home/service/s1',
      overrides: [
        serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
      ],
    );

    expect(find.text('Limpieza profunda'), findsOneWidget);
    expect(find.text('Limpieza'), findsOneWidget);
    expect(
      find.text('Cocina, baños y habitaciones de arriba a abajo.'),
      findsOneWidget,
    );
    expect(find.byType(ManoPrimaryButton), findsOneWidget);
  });

  testWidgets('"Ver ofertas" opens the offers for this service', (
    tester,
  ) async {
    final container = await pumpRouterAt(
      tester,
      '/home/service/s1',
      overrides: [
        serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
      ],
    );

    await tester.tap(find.text('Ver ofertas'));
    await tester.pumpAndSettle();

    expect(routerPath(container), '/home/service/s1/offers');
  });

  testWidgets('an unknown service shows a friendly not-found state', (
    tester,
  ) async {
    await pumpRouterAt(
      tester,
      '/home/service/nope',
      overrides: [
        serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
      ],
    );

    expect(find.textContaining('No encontramos este servicio'), findsOneWidget);
    expect(find.text('Ver ofertas'), findsNothing);
  });

  testWidgets('a failed load offers a retry that recovers', (tester) async {
    final catalog = _BrokenCatalog();
    await pumpRouterAt(
      tester,
      '/home/service/s1',
      overrides: [serviceCatalogProvider.overrideWithValue(catalog)],
    );

    expect(find.textContaining('No pudimos cargar'), findsOneWidget);

    catalog.broken = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Limpieza profunda'), findsOneWidget);
  });
}
