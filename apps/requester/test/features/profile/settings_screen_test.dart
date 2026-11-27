import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/config.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('notification toggles change the local preferences', (
    tester,
  ) async {
    final container = await pumpRouterAt(tester, '/profile/settings');

    expect(find.text('Configuración'), findsOneWidget);
    expect(find.byType(ManoToggleRow), findsNWidgets(4));
    await tester.tap(find.text('Promociones y novedades'));
    await tester.pumpAndSettle();

    expect(container.read(notificationPreferencesProvider).promotions, isTrue);
  });

  testWidgets('language is fixed to Español for now', (tester) async {
    await pumpRouterAt(tester, '/profile/settings');

    final row = tester.widget<ManoOptionRow>(
      find.widgetWithText(ManoOptionRow, 'Idioma'),
    );
    expect(row.detail, 'Español');
    expect(row.onPressed, isNull);
  });

  testWidgets('shows the app version and the terms', (tester) async {
    await pumpRouterAt(tester, '/profile/settings');

    await tester.scrollUntilVisible(
      find.text('Versión $requesterAppVersion'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Versión $requesterAppVersion'), findsOneWidget);
    await tester.tap(find.text('Términos y privacidad'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoPromptSheet), findsOneWidget);
  });

  testWidgets('Modo oscuro switches the app dark and saves it', (tester) async {
    final store = InMemoryAppearanceStore();
    final container = await pumpRouterAt(
      tester,
      '/profile/settings',
      overrides: [appearanceStoreProvider.overrideWithValue(store)],
    );

    await tester.tap(find.text('Modo oscuro'));
    await tester.pumpAndSettle();

    expect(container.read(darkModeProvider), isTrue);
    expect(await store.readDark(), isTrue);
  });
}
