import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

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
  return pumpRouterAt(tester, '/profile/addresses');
}

Future<void> _add(SavedAddress address, ProviderContainer container) =>
    container.read(addressBookActionsProvider.notifier).add(address);

void main() {
  testWidgets('an empty book invites the first address', (tester) async {
    await _open(tester);

    expect(find.text('Direcciones guardadas'), findsOneWidget);
    expect(find.byType(ManoEmptyState), findsOneWidget);
  });

  testWidgets('adds an address through the form; the first is default', (
    tester,
  ) async {
    final container = await _open(tester);

    await tester.tap(find.text('Agregar dirección'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Nombre'), 'Casa');
    await tester.enterText(_field('Dirección'), 'Calle 45 # 12-30');
    await tester.enterText(_field('Barrio'), 'Chapinero');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Predeterminada'), findsOneWidget);
    expect(find.textContaining('Chapinero'), findsOneWidget);
    expect(await container.read(savedAddressesProvider.future), hasLength(1));
  });

  testWidgets('the form refuses an incomplete address', (tester) async {
    final container = await _open(tester);

    await tester.tap(find.text('Agregar dirección'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe un nombre.'), findsOneWidget);
    expect(find.text('Escribe tu dirección.'), findsOneWidget);
    expect(await container.read(savedAddressesProvider.future), isEmpty);
  });

  testWidgets('edits and makes another address the default', (tester) async {
    final container = await _open(tester);
    await _add(
      const SavedAddress(label: 'Casa', line: 'Calle 45 # 12-30'),
      container,
    );
    await _add(
      const SavedAddress(label: 'Trabajo', line: 'Carrera 7 # 71-21'),
      container,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trabajo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar como predeterminada'));
    await tester.pumpAndSettle();
    expect(
      (await container.read(defaultAddressProvider.future))?.label,
      'Trabajo',
    );

    await tester.tap(find.text('Trabajo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Nombre'), 'Oficina');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Oficina'), findsOneWidget);
    expect(find.text('Trabajo'), findsNothing);
  });

  testWidgets('deleting asks first', (tester) async {
    final container = await _open(tester);
    await _add(
      const SavedAddress(label: 'Casa', line: 'Calle 45 # 12-30'),
      container,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Casa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar Casa?'), findsOneWidget);
    await tester.tap(find.text('Sí, eliminar'));
    await tester.pumpAndSettle();

    expect(await container.read(savedAddressesProvider.future), isEmpty);
    expect(find.byType(ManoEmptyState), findsOneWidget);
  });
}
