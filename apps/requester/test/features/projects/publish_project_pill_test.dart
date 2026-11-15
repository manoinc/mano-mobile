import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/activity/activity_list.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';
import '../activity/activity_fakes.dart';
import 'projects_fakes.dart';

final _pill = find.byKey(const Key('publish-project-pill'));

void main() {
  testWidgets('a guest is asked to sign in before publishing', (tester) async {
    await pumpRouterAt(tester, '/projects');

    await tester.tap(_pill);
    await tester.pumpAndSettle();

    expect(find.text('Necesitas una cuenta'), findsOneWidget);
  });

  testWidgets('with an account, the pill opens the publish flow', (
    tester,
  ) async {
    final container = await pumpRouterAt(
      tester,
      '/projects',
      session: signedIn(),
    );

    await tester.tap(_pill);
    await tester.pumpAndSettle();

    expect(routerPath(container), '/publish');
  });

  testWidgets('every filter keeps the pill', (tester) async {
    await pumpRouterAt(tester, '/projects');

    for (final filter in ['En curso', 'Historial', 'Pendientes']) {
      await tester.tap(find.text(filter));
      await tester.pumpAndSettle();
      expect(_pill, findsOneWidget, reason: filter);
    }
  });

  group('one flame per screen: the shell owns it', () {
    Future<void> expectQuietPill(WidgetTester tester) async {
      expect(
        find.descendant(
          of: find.byType(ActivityList),
          matching: find.byType(ManoPrimaryButton),
        ),
        findsNothing,
      );
      expect(_pill, findsOneWidget);
      expect(
        find.descendant(of: _pill, matching: find.byType(FilledButton)),
        findsNothing,
      );
      // Compact, not full width.
      final list = tester.getSize(find.byType(ActivityList));
      expect(tester.getSize(_pill).width, lessThan(list.width * 0.75));
    }

    testWidgets('with activity, Publicar proyecto is a quiet pill', (
      tester,
    ) async {
      await pumpRouterAt(tester, '/projects');
      await expectQuietPill(tester);
    });

    testWidgets('an empty filter uses the same quiet pill', (tester) async {
      await pumpRouterAt(tester, '/projects', overrides: emptyActivity());
      expect(find.byType(ManoEmptyState), findsOneWidget);
      await expectQuietPill(tester);
    });
  });
}
