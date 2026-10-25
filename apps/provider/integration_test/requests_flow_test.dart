import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mano_provider/main.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

Finder _inCard(String id, String text) => find.descendant(
  of: find.byKey(Key('request-card-$id')),
  matching: find.text(text),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) => _tap(
  tester,
  find.descendant(
    of: find.byType(ManoProjectFilterTabs),
    matching: find.text(label),
  ),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a provider accepts one request and rejects another', (
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

    await _tap(tester, _inCard('request-1', 'Aceptar · 2 coins'));
    expect(
      find.text('Solicitud aceptada · quedó en tu agenda'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('request-card-request-1')), findsNothing);

    await _tap(tester, _inCard('request-2', 'Rechazar'));
    await tester.enterText(find.byType(TextField), 'Sin cupo');
    await _tap(tester, find.text('Rechazar solicitud'));
    expect(find.text('Solicitud rechazada'), findsOneWidget);

    await _openTab(tester, 'Respondidas');
    expect(_inCard('request-1', 'Aceptada'), findsOneWidget);
    expect(_inCard('request-2', 'Rechazada'), findsOneWidget);
  });
}
