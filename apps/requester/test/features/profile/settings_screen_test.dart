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
    expect(find.byType(ManoToggleRow), findsNWidgets(3));
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

    expect(find.text('Versión $requesterAppVersion'), findsOneWidget);
    await tester.tap(find.text('Términos y privacidad'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoPromptSheet), findsOneWidget);
  });
}
