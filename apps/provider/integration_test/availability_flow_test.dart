import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mano_provider/features/availability/availability_view.dart';
import 'package:mano_provider/main.dart';
import 'package:mano_provider/shell/provider_nav_shell.dart';
import 'package:mano_provider/shell/provider_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.descendant(
      of: find.byType(AvailabilityView),
      matching: find.byType(Scrollable),
    ),
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
          offlineMarketplaceProvider.overrideWithValue(true),
          manoConfigProvider.overrideWithValue(testConfig),
          sessionRepositoryProvider.overrideWithValue(
            FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
          ),
        ],
        child: const ProviderApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    // The entry link belongs to PROV-02, so drive the router directly.
    ProviderScope.containerOf(tester.element(find.byType(ProviderNavShell)))
        .read(providerRouterProvider)
        .go('/agenda?tab=availability');
    await tester.pumpAndSettle();
    expect(find.byType(AvailabilityView), findsOneWidget);

    await tester.tap(find.text('Agregar horario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('D'));
    await tester.drag(
      find.byKey(const Key('mano-time-wheel-start')),
      const Offset(0, -4 * ManoTimeRangePicker.itemExtent),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('dom · 10:00 a. m. – 12:00 p. m.'), findsOneWidget);

    await _scrollTo(tester, find.text('Generar enlace'));
    await tester.tap(find.text('Generar enlace'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Copiar enlace'));
    expect(find.textContaining('no lo volveremos a mostrar'), findsOneWidget);

    await _scrollTo(tester, find.byTooltip('Más opciones'));
    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desactivar enlace'));
    await tester.pumpAndSettle();
    expect(find.text('No conectado'), findsOneWidget);
  });
}
