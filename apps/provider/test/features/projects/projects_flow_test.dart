import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';
import '../services/services_fakes.dart';
import 'projects_fakes.dart';

// The host twin of integration_test/projects_flow_test.dart.

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a provider quotes on an open project', (tester) async {
    await pumpRouterAt(
      tester,
      '/home',
      session: signedIn(),
      overrides: [
        serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
      ],
    );

    await _tap(
      tester,
      find.descendant(
        of: find.byType(ManoProjectFilterTabs).first,
        matching: find.text('Proyectos'),
      ),
    );
    await _tap(tester, find.byKey(const Key('lead-card-project-5')));
    await _tap(tester, find.text('Cotizar gratis'));
    for (final key in ['4', '2', '000', '0']) {
      await _tap(tester, find.text(key));
    }
    await _tap(tester, find.text('Enviar cotización'));

    expect(find.text(r'Ya cotizaste · $420.000'), findsOneWidget);

    await _tap(tester, find.byType(BackButton));
    await _tap(
      tester,
      find.descendant(
        of: find.byType(ManoProjectFilterTabs).first,
        matching: find.text('Mis cotizaciones'),
      ),
    );
    expect(find.text('Limpieza final de obra'), findsOneWidget);
  });
}
