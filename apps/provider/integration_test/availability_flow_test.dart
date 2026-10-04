import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mano_provider/features/availability/availability_screen.dart';
import 'package:mano_provider/main.dart';
import 'package:mano_provider/shell/provider_nav_shell.dart';
import 'package:mano_provider/shell/provider_router.dart';
import 'package:mano_session/mano_session.dart';

import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a provider adds hours and manages the calendar link', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          manoConfigProvider.overrideWithValue(testConfig),
          sessionRepositoryProvider.overrideWithValue(
            FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
          ),
        ],
        child: const ProviderApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Servicios'));
    await tester.pumpAndSettle();
    // The entry link belongs to PROV-02, so drive the router directly.
    ProviderScope.containerOf(tester.element(find.byType(ProviderNavShell)))
        .read(providerRouterProvider)
        .push('/services/availability');
    await tester.pumpAndSettle();
    expect(find.byType(AvailabilityScreen), findsOneWidget);

    await tester.tap(find.text('Agregar horario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('D'));
    await tester.tap(find.byKey(const Key('rule-start')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('10:00 a. m.'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('10:00 a. m.').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('dom · 10:00 a. m. – 12:00 p. m.'), findsOneWidget);

    await _scrollTo(tester, find.text('Generar enlace'));
    await tester.tap(find.text('Generar enlace'));
    await tester.pumpAndSettle();
    expect(find.textContaining('https://'), findsOneWidget);

    await _scrollTo(tester, find.text('Desactivar enlace'));
    await tester.tap(find.text('Desactivar enlace'));
    await tester.pumpAndSettle();
    expect(find.textContaining('https://'), findsNothing);
    expect(find.text('Generar enlace'), findsOneWidget);
  });
}
