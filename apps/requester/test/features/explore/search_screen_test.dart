import 'dart:async';

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

Finder _tile(String label) => find.widgetWithText(ManoCategoryTile, label);

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

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on a grid of every category, without searching', (
    tester,
  ) async {
    final catalog = await _open(tester);

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(ManoCategoryTile), findsNWidgets(5));
    for (final label in [
      'Limpieza',
      'Plomería',
      'Electricidad',
      'Pintura',
      'Jardinería',
    ]) {
      expect(_tile(label), findsOneWidget);
    }
    expect(find.byType(GridView), findsOneWidget);
    expect(catalog.searches, isEmpty);
  });

  testWidgets('the grid fits a small phone at double text size', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _open(tester);

    expect(tester.takeException(), isNull);
    expect(_tile('Jardinería'), findsOneWidget);
  });

  testWidgets('each tile shows its category photo', (tester) async {
    await _open(tester);

    final image = tester.widget<Image>(
      find.descendant(of: _tile('Plomería'), matching: find.byType(Image)),
    );
    expect(
      (image.image as AssetImage).assetName,
      'assets/categories/plumbing.jpg',
    );
  });

  testWidgets('a back chevron and an autofocused pill sit on top', (
    tester,
  ) async {
    await _open(tester);

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('¿Con qué necesitas ayuda?'), findsOneWidget);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);
  });

  testWidgets('arriving with a category keeps the keyboard down', (
    tester,
  ) async {
    await _open(tester, location: '/home/search?category=plumbing');

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isFalse);
  });

  testWidgets('typing searches only once the user pauses', (tester) async {
    final catalog = await _open(tester);

    await tester.enterText(find.byType(TextField), 'fuga');
    await tester.pump(const Duration(milliseconds: 100));
    expect(catalog.searches, isEmpty);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(catalog.searches.last, (category: null, text: 'fuga'));
    expect(find.text('Reparación de fugas'), findsOneWidget);
    expect(find.text('Limpieza profunda'), findsNothing);
    expect(find.byType(ManoCategoryTile), findsNothing);
  });

  testWidgets('results show title, category and description', (tester) async {
    await _open(tester);

    await _type(tester, 'limpieza');

    expect(find.text('Limpieza profunda'), findsOneWidget);
    expect(
      find.text('Cocina, baños y habitaciones de arriba a abajo.'),
      findsOneWidget,
    );
  });

  testWidgets('clearing the text goes back to the grid', (tester) async {
    await _open(tester);
    await _type(tester, 'fuga');

    await _type(tester, '');

    expect(find.byType(ManoCategoryTile), findsNWidgets(5));
  });

  testWidgets('shows the Mano loader while results load', (tester) async {
    final catalog = FakeServiceCatalog()..hold = Completer<void>();
    await _open(tester, catalog: catalog);

    await tester.enterText(find.byType(TextField), 'fuga');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.byType(ManoLoader), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    catalog.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ManoLoader), findsNothing);
    expect(find.text('Reparación de fugas'), findsOneWidget);
  });

  testWidgets('tapping a tile filters to that category', (tester) async {
    final catalog = await _open(tester);

    await tester.tap(_tile('Limpieza'));
    await tester.pumpAndSettle();

    expect(catalog.searches.last, (category: 'cleaning', text: null));
    expect(find.text('Limpieza profunda'), findsOneWidget);
    expect(find.text('Reparación de fugas'), findsNothing);
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

  testWidgets('a chip switches category; tapping it again shows the grid', (
    tester,
  ) async {
    final catalog = await _open(
      tester,
      location: '/home/search?category=cleaning',
    );

    await tester.tap(_chip('Plomería'));
    await tester.pumpAndSettle();
    expect(catalog.searches.last, (category: 'plumbing', text: null));
    expect(find.text('Limpieza profunda'), findsNothing);

    await tester.tap(_chip('Plomería'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoCategoryTile), findsNWidgets(5));
  });

  testWidgets('no matches shows the empty state, which clears the search', (
    tester,
  ) async {
    await _open(tester, location: '/home/search?category=gardening');

    expect(find.textContaining('No encontramos servicios'), findsOneWidget);

    await tester.tap(find.text('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoCategoryTile), findsNWidgets(5));
  });

  testWidgets('a failed search offers a retry that recovers', (tester) async {
    final catalog = FakeServiceCatalog()..searchError = Exception('down');
    await _open(
      tester,
      catalog: catalog,
      location: '/home/search?category=cleaning',
    );

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
      '/home/search?category=plumbing',
      overrides: [serviceCatalogProvider.overrideWithValue(catalog)],
    );

    await tester.tap(find.text('Reparación de fugas'));
    await tester.pumpAndSettle();

    expect(routerPath(container), '/home/service/s2');
  });
}
