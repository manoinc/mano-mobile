import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/projects/publish/publish_project_screen.dart';
import 'package:mano_session/mano_session.dart';

import '../../support/pump_app.dart';
import 'projects_fakes.dart';

bool _continueEnabled(WidgetTester tester, [String label = 'Continuar']) =>
    tester
        .widget<FilledButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(FilledButton),
          ),
        )
        .enabled;

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _describe(WidgetTester tester) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('project-title')),
      matching: find.byType(TextField),
    ),
    'Pintar la sala',
  );
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('project-description')),
      matching: find.byType(TextField),
    ),
    'Dos paredes con humedad.',
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the router builds the flow at /publish', (tester) async {
    await pumpRouterAt(tester, '/publish', session: signedIn());
    expect(find.byType(PublishProjectScreen), findsOneWidget);
    expect(find.text('¿Qué necesitas?'), findsOneWidget);
  });

  testWidgets(
    'Continuar waits for a category, then for title and description',
    (tester) async {
      await pumpRouterAt(tester, '/publish', session: signedIn());
      expect(_continueEnabled(tester), isFalse);

      await _tap(tester, 'Pintura');
      expect(_continueEnabled(tester), isTrue);
      await _tap(tester, 'Continuar');

      expect(find.text('Cuéntanos el trabajo'), findsOneWidget);
      expect(_continueEnabled(tester), isFalse);
      await _describe(tester);
      expect(_continueEnabled(tester), isTrue);
    },
  );

  testWidgets('a preselected category starts at the details', (tester) async {
    await pumpRouterAt(
      tester,
      '/publish?category=plumbing',
      session: signedIn(),
    );

    expect(find.text('Cuéntanos el trabajo'), findsOneWidget);
    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué necesitas?'), findsOneWidget);
  });

  testWidgets('the keypad sets the budget, Omitir clears it', (tester) async {
    await pumpRouterAt(
      tester,
      '/publish?category=painting',
      session: signedIn(),
    );
    await _describe(tester);
    await _tap(tester, 'Continuar');

    for (final key in ['1', '8', '0', '0', '000']) {
      await tester.ensureVisible(find.text(key));
      await tester.tap(find.text(key));
      await tester.pump();
    }
    expect(find.text(r'$1.800.000'), findsOneWidget);

    await _tap(tester, 'Continuar');
    expect(find.text('Revisa y publica'), findsOneWidget);
    expect(find.text(r'Presupuesto  $1.800.000'), findsOneWidget);

    await tester.tap(find.text('Editar').last);
    await tester.pumpAndSettle();
    await _tap(tester, 'Omitir');
    expect(find.text('Presupuesto  Sin presupuesto'), findsOneWidget);
  });

  testWidgets('publishing confirms, then opens the new project', (
    tester,
  ) async {
    final container = await pumpRouterAt(
      tester,
      '/publish?category=painting',
      session: signedIn(),
    );
    await _describe(tester);
    await _tap(tester, 'Continuar');
    await _tap(tester, 'Omitir');

    expect(find.text('Pintar la sala'), findsOneWidget);
    await _tap(tester, 'Publicar proyecto');
    expect(find.text('Proyecto publicado'), findsOneWidget);

    await _tap(tester, 'Ver proyecto');
    expect(routerPath(container), startsWith('/projects/project/'));
    expect(find.text('Pintar la sala'), findsOneWidget);
    expect(find.text('Aún no hay cotizaciones.'), findsOneWidget);
  });

  testWidgets('a refused publish says so and stays on the review', (
    tester,
  ) async {
    await pumpRouterAt(
      tester,
      '/publish?category=painting',
      session: signedIn(),
      overrides: [projectRepositoryProvider.overrideWithValue(FakeProjects())],
    );
    await _describe(tester);
    await _tap(tester, 'Continuar');
    await _tap(tester, 'Omitir');
    await _tap(tester, 'Publicar proyecto');

    expect(find.text(const DataUnavailable().message), findsOneWidget);
    expect(find.text('Revisa y publica'), findsOneWidget);
  });
}
