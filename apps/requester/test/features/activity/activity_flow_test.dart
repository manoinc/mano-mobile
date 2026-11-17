import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';

// Host-side twin of integration_test/activity_flow_test.dart.
Future<void> _openFilter(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(ManoProjectFilterTabs),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a cancelled job moves from En curso to Historial', (
    tester,
  ) async {
    final c = await pumpRouterAt(tester, '/projects');
    await _openFilter(tester, 'En curso');

    await tester.tap(find.byKey(const Key('activity-job-job-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byType(BackButton),
    ); // locale-proof, unlike pageBack()
    await tester.pumpAndSettle();
    expect(routerPath(c), '/projects');
    expect(find.byKey(const Key('activity-job-job-1')), findsNothing);
    await _openFilter(tester, 'Historial');
    expect(find.byKey(const Key('activity-job-job-1')), findsOneWidget);
  });
}
