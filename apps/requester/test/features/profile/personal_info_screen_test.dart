import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/shell/app_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_media.dart';
import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

Finder _field(String label) => find.descendant(
  of: find.widgetWithText(ManoTextField, label),
  matching: find.byType(TextField),
);

Future<ProviderContainer> _open(
  WidgetTester tester, {
  MediaUploader? uploader,
  FakeMediaPicker? picker,
}) => pumpRouterAt(
  tester,
  '/profile/personal',
  session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
  overrides: [
    mediaPickerProvider.overrideWithValue(picker ?? FakeMediaPicker()),
    if (uploader != null) mediaUploaderProvider.overrideWithValue(uploader),
  ],
);

void main() {
  testWidgets('starts from what the account already knows', (tester) async {
    await _open(tester);

    expect(find.text('Información personal'), findsOneWidget);
    expect(
      tester.widget<TextField>(_field('Nombre completo')).controller!.text,
      'mano-test',
    );
  });

  testWidgets('Guardar shows what is missing instead of saving', (
    tester,
  ) async {
    final container = await _open(tester);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu celular.'), findsOneWidget);
    // The email is optional: a phone account has none.
    expect(find.text('Escribe tu correo.'), findsNothing);
    expect((await container.read(clientProfileProvider.future)).phone, isEmpty);
  });

  testWidgets('Guardar keeps a complete profile and goes back', (tester) async {
    final container = await _open(tester);
    container.read(requesterRouterProvider).go('/profile');
    await tester.pumpAndSettle();
    container.read(requesterRouterProvider).push('/profile/personal');
    await tester.pumpAndSettle();

    await tester.enterText(_field('Nombre completo'), 'Ana Rojas');
    await tester.enterText(_field('Celular'), '300 123 4567');
    await tester.enterText(_field('Correo'), 'ana@mano.co');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final saved = await container.read(clientProfileProvider.future);
    expect(saved.displayName, 'Ana Rojas');
    expect(saved.phone, '300 123 4567');
    expect(routerPath(container), '/profile');
    expect(find.text('Guardamos tus datos.'), findsOneWidget);
    expect(find.text('Ana Rojas'), findsOneWidget);
  });

  testWidgets('a new photo shows at once, uploads as the avatar and is kept', (
    tester,
  ) async {
    final uploader = HeldMediaUploader();
    final picker = FakeMediaPicker();
    final container = await _open(tester, uploader: uploader, picker: picker);

    await tester.tap(find.byType(ManoAvatarEditor));
    await tester.pumpAndSettle();
    expect(find.byType(ManoMediaSourceSheet), findsOneWidget);
    await tester.tap(find.text('Elegir de la galería'));
    await tester.pump();
    await tester.pump();

    expect(picker.sources, [PhotoSource.gallery]);
    expect(uploader.targets, [const AvatarUpload()]);
    final shown = tester.widget<Image>(
      find.descendant(
        of: find.byType(ManoAvatarEditor),
        matching: find.byType(Image),
      ),
    );
    expect(shown.image, isA<MemoryImage>());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    uploader.succeed('https://cdn.mano.co/avatar.png');
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      (await container.read(clientProfileProvider.future)).photoUrl,
      'https://cdn.mano.co/avatar.png',
    );
  });

  testWidgets('a failed upload says so and keeps the old photo', (
    tester,
  ) async {
    final uploader = HeldMediaUploader();
    final container = await _open(tester, uploader: uploader);

    await tester.tap(find.byType(ManoAvatarEditor));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomar foto'));
    await tester.pump();
    uploader.fail();
    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos subir tu foto. Intenta de nuevo.'),
      findsOneWidget,
    );
    expect(
      (await container.read(clientProfileProvider.future)).photoUrl,
      isNull,
    );
    expect(find.byIcon(Icons.person), findsOneWidget);
  });
}
