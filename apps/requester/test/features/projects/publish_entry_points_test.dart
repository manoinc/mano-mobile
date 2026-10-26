import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';
import 'projects_fakes.dart';

void main() {
  testWidgets('Home offers a quiet way into publishing', (tester) async {
    final container = await pumpRouterAt(tester, '/home', session: signedIn());

    await tester.tap(find.byKey(const Key('home-publish-project')));
    await tester.pumpAndSettle();

    expect(routerPath(container), '/publish');
  });

  testWidgets('a category in the create sheet skips to the details', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/home', session: signedIn());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plomería').last);
    await tester.pumpAndSettle();

    expect(find.text('Cuéntanos el trabajo'), findsOneWidget);
  });

  testWidgets('a guest tapping the create sheet is asked to sign in', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/home');

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publicar proyecto'));
    await tester.pumpAndSettle();

    expect(find.text('Necesitas una cuenta'), findsOneWidget);
  });
}
