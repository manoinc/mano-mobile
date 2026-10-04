import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mano_requester/main.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a requester sends a message and sees the reply', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          manoConfigProvider.overrideWithValue(testConfig),
          sessionRepositoryProvider.overrideWithValue(
            FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
          ),
        ],
        child: const RequesterApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bandeja'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ManoConversationTile).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hola');
    await tester.tap(find.byKey(const Key('mano-composer-send')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ManoChatBubble, 'Hola'), findsOneWidget);

    const reply = '¡Recibido! Te respondo en un momento.';
    for (var i = 0; i < 30 && find.text(reply).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.widgetWithText(ManoChatBubble, reply), findsOneWidget);
  });
}
