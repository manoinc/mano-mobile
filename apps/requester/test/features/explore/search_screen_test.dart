import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/explore/search_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';
import 'fake_service_catalog.dart';

Finder _chip(String label) => find.descendant(
  of: find.byType(ManoCategoryRail),
  matching: find.text(label),
);

Future<FakeServiceCatalog> _open(
  WidgetTester tester, {
  String location = '/home/search',
  FakeServiceCatalog? catalog,
}) async {
  final fake = catalog ?? FakeServiceCatalog();
  await pumpRouterAt(
    tester,
    location,
    overrides: [serviceCatalogProvider.overrideWithValue(fake)],
  );
  return fake;
}

void main() {
  testWidgets('opens on every service with title, category and description', (
    tester,
  ) async {
    final catalog = await _open(tester);

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('Limpieza profunda'), findsOneWidget);
    expect(find.text('Reparación de fugas'), findsOneWidget);
    expect(find.text('Plomería'), findsNWidgets(2));
    expect(
      find.text('Cocina, baños y habitaciones de arriba a abajo.'),
      findsOneWidget,
    );
    expect(catalog.searches.last, (category: null, text: null));
  });

  testWidgets('the search field is autofocused', (tester) async {
    await _open(tester);

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);
  });

  testWidgets('typing searches only once the user pauses', (tester) async {
    final catalog = await _open(tester);
    final before = catalog.searches.length;

    await tester.enterText(find.byType(TextField), 'fuga');
    await tester.pump(const Duration(milliseconds: 100));
    expect(catalog.searches.length, before);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(catalog.searches.last, (category: null, text: 'fuga'));
    expect(find.text('Reparación de fugas'), findsOneWidget);
    expect(find.text('Limpieza profunda'), findsNothing);
  });

  testWidgets('a category from the route is preselected and filters', (
    tester,
  ) async {
    final catalog = await _open(
      tester,
      location: '/home/search?category=cleaning',
    );

    expect(catalog.searches.last, (category: 'cleaning', text: null));
    expect(
      tester
          .widget<ManoCategoryChip>(
            find.ancestor(
              of: _chip('Limpieza'),
              matching: find.byType(ManoCategoryChip),
            ),
          )
          .selected,
      isTrue,
    );
    expect(find.text('Reparación de fugas'), findsNothing);
  });

  testWidgets('tapping a chip filters and tapping it again clears', (
    tester,
  ) async {
    final catalog = await _open(tester);

    await tester.tap(_chip('Plomería'));
    await tester.pumpAndSettle();
    expect(catalog.searches.last, (category: 'plumbing', text: null));
    expect(find.text('Limpieza profunda'), findsNothing);

    await tester.tap(_chip('Plomería'));
    await tester.pumpAndSettle();
    expect(catalog.searches.last, (category: null, text: null));
    expect(find.text('Limpieza profunda'), findsOneWidget);
  });

  testWidgets('no matches shows the empty state, which clears the search', (
    tester,
  ) async {
    await _open(tester, location: '/home/search?category=gardening');

    expect(find.textContaining('No encontramos servicios'), findsOneWidget);

    await tester.tap(find.text('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('Limpieza profunda'), findsOneWidget);
  });

  testWidgets('a failed search offers a retry that recovers', (tester) async {
    final catalog = FakeServiceCatalog()..searchError = Exception('down');
    await _open(tester, catalog: catalog);

    expect(find.textContaining('No pudimos cargar'), findsOneWidget);

    catalog.searchError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Limpieza profunda'), findsOneWidget);
  });

  testWidgets('tapping a result opens its detail', (tester) async {
    final catalog = FakeServiceCatalog();
    final container = await pumpRouterAt(
      tester,
      '/home/search',
      overrides: [serviceCatalogProvider.overrideWithValue(catalog)],
    );

    await tester.tap(find.text('Reparación de fugas'));
    await tester.pumpAndSettle();

    expect(routerPath(container), '/home/service/s2');
  });
}
