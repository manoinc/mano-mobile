import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mano_requester/main.dart';
import 'package:mano_requester/shell/nav_shell.dart';
import 'package:mano_session/mano_session.dart';

import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a signed-in requester can visit every tab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMarketplaceProvider.overrideWithValue(true),
          manoConfigProvider.overrideWithValue(testConfig),
          sessionRepositoryProvider.overrideWithValue(
            FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
          ),
        ],
        child: const RequesterApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavShell), findsOneWidget);
    for (final tab in ['Actividad', 'Bandeja', 'Perfil', 'Inicio']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
    }
    expect(find.byType(NavShell), findsOneWidget);
  });
}
