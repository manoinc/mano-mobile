import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_media.dart';
import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';
import '../services/services_fakes.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String path = '/profile/edit',
  bool signedIn = true,
}) async {
  tester.view.physicalSize = const Size(1080, 7200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = await pumpRouterAt(
    tester,
    path,
    overrides: [
      serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
      ...fakeMediaOverrides(),
    ],
    session: signedIn
        ? FakeSessionRepository(onRestore: () async => Ok(fakeSession()))
        : null,
  );
  await tester.pumpAndSettle();
  return container;
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(ManoTextField)),
  matching: find.byType(TextField),
);

Future<void> _tapSave(WidgetTester tester) async {
  await tester.tap(find.text('Guardar cambios'));
  await tester.pumpAndSettle();
}

Future<ProviderProfile> _profile(ProviderContainer c) =>
    c.read(providerProfileProvider.future);

void main() {
  testWidgets('Editar perfil on Perfil opens the form, filled in', (
    tester,
  ) async {
    final c = await _pump(tester, path: '/profile');
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/profile/edit');
    expect(find.text('Andrés Castro'), findsOneWidget);
    expect(find.text('Chapinero'), findsOneWidget);
    expect(find.byType(ManoPhotoPickerGrid), findsOneWidget);
  });

  testWidgets('a guest is asked to sign in first', (tester) async {
    final c = await _pump(tester, path: '/profile', signedIn: false);
    c.read(sessionProvider.notifier).browseAsGuest();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();

    expect(find.byType(ManoAccountNeededSheet), findsOneWidget);
    expect(routerPath(c), '/profile');
  });

  testWidgets('saving updates Perfil', (tester) async {
    final c = await _pump(tester, path: '/profile');
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Nombre para mostrar'), 'Andrés C.');
    await tester.enterText(_field('Sobre ti'), 'Plomero de confianza.');
    await tester.tap(find.text('Electricidad'));
    await tester.pumpAndSettle();
    await _tapSave(tester);

    expect(routerPath(c), '/profile');
    expect(find.text('Andrés C.'), findsOneWidget);
    expect(find.text('Plomero de confianza.'), findsOneWidget);
    expect((await _profile(c)).skills, contains('electrical'));
  });

  testWidgets('an empty name holds Guardar shut and says why', (tester) async {
    await _pump(tester);
    await tester.enterText(_field('Nombre para mostrar'), ' ');
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu nombre.'), findsOneWidget);
    final save = tester.widget<ManoPrimaryButton>(
      find.widgetWithText(ManoPrimaryButton, 'Guardar cambios'),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('the bio counts down to its limit', (tester) async {
    await _pump(tester);
    await tester.enterText(_field('Sobre ti'), 'Hola');
    await tester.pumpAndSettle();
    expect(find.text('4/$providerBioMaxLength'), findsOneWidget);
  });

  testWidgets('zones are added and removed', (tester) async {
    final c = await _pump(tester);
    await tester.enterText(_field('Agregar zona'), 'Suba');
    await tester.tap(find.byTooltip('Agregar zona'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Quitar Chapinero'));
    await tester.pumpAndSettle();
    await _tapSave(tester);

    expect((await _profile(c)).zones, ['Usaquén', 'Teusaquillo', 'Suba']);
  });

  testWidgets('a new photo shows at once and is saved', (tester) async {
    final c = await _pump(tester);
    await tester.tap(find.text('Cambiar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir de la galería'));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage),
      findsOneWidget,
    );
    await _tapSave(tester);
    expect((await _profile(c)).party.photoUrl, 'https://x.test/upload-1.jpg');
  });

  testWidgets('portfolio photos are added and removed', (tester) async {
    final c = await _pump(tester);
    final before = (await _profile(c)).portfolioUrls;

    await tester.tap(find.text('Agregar fotos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Quitar foto 1'));
    await tester.pumpAndSettle();
    await _tapSave(tester);

    expect((await _profile(c)).portfolioUrls, [
      ...before.skip(1),
      'https://x.test/upload-1.jpg',
    ]);
  });

  group('unsaved changes', () {
    testWidgets('back with nothing changed just leaves', (tester) async {
      final c = await _pump(tester, path: '/profile');
      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(routerPath(c), '/profile');
    });

    testWidgets('back asks first; keep editing, then discard', (tester) async {
      final c = await _pump(tester, path: '/profile');
      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Sobre ti'), 'Algo nuevo');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar los cambios?'), findsOneWidget);

      await tester.tap(find.text('Seguir editando'));
      await tester.pumpAndSettle();
      expect(routerPath(c), '/profile/edit');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar cambios'));
      await tester.pumpAndSettle();

      expect(routerPath(c), '/profile');
      expect((await _profile(c)).bio, isNot('Algo nuevo'));
    });
  });
}
