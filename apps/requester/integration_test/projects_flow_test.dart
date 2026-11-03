import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mano_requester/main.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../test/support/fake_media_picker.dart';

import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a requester publishes a project, then chooses a quote', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMarketplaceProvider.overrideWithValue(true),
          manoConfigProvider.overrideWithValue(testConfig),
          sessionRepositoryProvider.overrideWithValue(
            FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
          ),
          mediaPickerProvider.overrideWithValue(FakeMediaPicker()),
        ],
        child: const RequesterApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Publish from the create sheet, with a category.
    await _tap(tester, find.byIcon(Icons.add));
    await _tap(tester, find.text('Pintura').last);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('project-title')),
        matching: find.byType(TextField),
      ),
      'Pintar el estudio',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('project-description')),
        matching: find.byType(TextField),
      ),
      'Una habitación de 12 m², color blanco.',
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Continuar'));

    // One photo of the problem; settling waits out the upload.
    await _tap(tester, find.text('Agregar fotos'));
    await _tap(tester, find.text('Elegir de la galería'));
    expect(find.byType(ManoPhotoPickerGrid), findsOneWidget);
    await _tap(tester, find.text('Continuar'));

    await _tap(tester, find.text('Omitir'));
    expect(find.text('1 foto'), findsOneWidget);
    await _tap(tester, find.text('Publicar proyecto'));
    expect(find.text('Proyecto publicado'), findsOneWidget);
    await _tap(tester, find.text('Ver proyecto'));
    expect(find.text('Pintar el estudio'), findsOneWidget);
    expect(find.byType(ManoPhotoGallery), findsOneWidget);

    // Back on Proyectos, open the one with quotes and choose the cheapest.
    await _tap(tester, find.byType(BackButton));
    expect(find.byKey(const Key('project-card-project-1')), findsOneWidget);
    await _tap(tester, find.byKey(const Key('project-card-project-1')));
    await _tap(
      tester,
      find.descendant(
        of: find.byKey(const Key('quote-quote-3')),
        matching: find.text('Elegir'),
      ),
    );
    await _tap(tester, find.text('Elegir cotización'));

    expect(find.text('Elegida'), findsOneWidget);
  });
}
