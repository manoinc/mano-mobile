import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mano_requester/main.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

Future<void> _openFilter(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(ManoProjectFilterTabs).last,
    matching: find.text(label),
  );
  await tester.dragUntilVisible(
    tab,
    find.byType(ManoProjectFilterTabs).last,
    const Offset(-120, 0),
  );
  await tester.pumpAndSettle();
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Widget _app() => ProviderScope(
  overrides: [
    offlineMarketplaceProvider.overrideWithValue(true),
    manoConfigProvider.overrideWithValue(testConfig),
    sessionRepositoryProvider.overrideWithValue(
      FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    ),
  ],
  child: const RequesterApp(),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a requester cancels a scheduled job from Actividad', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Actividad'));
    await tester.pumpAndSettle();
    await _openFilter(tester, 'Programados');

    await tester.tap(find.byKey(const Key('activity-job-job-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Trabajo cancelado'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byType(BackButton),
    ); // locale-proof, unlike pageBack()
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('activity-job-job-1')), findsNothing);
    await _openFilter(tester, 'Cancelados');
    expect(find.byKey(const Key('activity-job-job-1')), findsOneWidget);
  });

  testWidgets('a requester rates a finished job (HU-C6)', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Actividad'));
    await tester.pumpAndSettle();
    await _openFilter(tester, 'Finalizados');
    await tester.tap(find.byKey(const Key('activity-job-job-5')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calificar'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('5 estrellas'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Muy puntual');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text('¡Gracias por calificar!'), findsOneWidget);
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(find.text('Calificado ★5'), findsOneWidget);
    expect(find.text('Volver a contratar'), findsOneWidget);
  });
}
