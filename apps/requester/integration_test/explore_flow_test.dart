import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mano_requester/main.dart';
import 'package:mano_requester/shell/app_router.dart';
import 'package:mano_requester/shell/nav_shell.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../test/features/explore/fake_service_catalog.dart';
import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a requester searches, opens a service and reaches its offers', (
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
          // The gateway may not be running; the flow is about navigation.
          serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
        ],
        child: const RequesterApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavShell), findsOneWidget);

    await tester.tap(find.byType(ManoSearchPill));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'fuga');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Limpieza profunda'), findsNothing);

    await tester.tap(find.text('Reparación de fugas'));
    await tester.pumpAndSettle();
    expect(find.text('Arreglamos llaves, tuberías y sifones.'), findsOneWidget);

    await tester.tap(find.text('Ver ofertas'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(NavShell)),
    );
    expect(
      container.read(requesterRouterProvider).state.uri.path,
      '/home/service/s2/offers',
    );
  });
}
