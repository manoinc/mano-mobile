import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';
import 'projects_fakes.dart';

// The host twin of integration_test/projects_flow_test.dart.

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a requester publishes a project, then chooses a quote', (
    tester,
  ) async {
    final c = await pumpRouterAt(tester, '/home', session: signedIn());

    await _tap(tester, find.byIcon(Icons.add));
    await _tap(tester, find.text('Pintura').last);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('project-title')),
        matching: find.byType(TextField),
      ),
      'Pintar el estudio',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('project-description')),
        matching: find.byType(TextField),
      ),
      'Una habitación de 12 m², color blanco.',
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Continuar'));
    await _tap(tester, find.text('Omitir'));
    await _tap(tester, find.text('Publicar proyecto'));
    await _tap(tester, find.text('Ver proyecto'));
    expect(find.text('Pintar el estudio'), findsOneWidget);

    await _tap(tester, find.byType(BackButton));
    expect(routerPath(c), '/projects');
    await _tap(tester, find.byKey(const Key('project-card-project-1')));
    await _tap(
      tester,
      find.descendant(
        of: find.byKey(const Key('quote-quote-3')),
        matching: find.text('Elegir'),
      ),
    );
    await _tap(tester, find.text('Elegir cotización'));

    expect(find.text('Elegida'), findsOneWidget);
  });
}
