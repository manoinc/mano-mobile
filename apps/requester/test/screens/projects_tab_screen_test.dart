import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/activity/activity_list.dart';
import 'package:mano_requester/screens/projects_tab_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../features/activity/activity_fakes.dart';
import '../features/projects/projects_fakes.dart';
import '../support/pump_app.dart';

Finder _card(String key) => find.byKey(Key(key));

final _list = find
    .descendant(
      of: find.byType(ActivityList),
      matching: find.byType(Scrollable),
    )
    .last;

/// Tall enough that every list renders whole.
Future<void> _tall(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Every card in the list, top to bottom, by key.
List<String> _order(WidgetTester tester) => [
  for (final e
      in find
          .byWidgetPredicate(
            (w) => w is ManoProjectCard || w is ManoProjectSummaryCard,
          )
          .evaluate())
    (e.widget.key! as ValueKey<String>).value,
];

void main() {
  testWidgets('the router builds the tab at /projects', (tester) async {
    await pumpRouterAt(tester, '/projects');
    expect(find.byType(ProjectsTabScreen), findsOneWidget);
  });

  testWidgets('one filter row: Pendientes, En curso, Historial', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/projects');

    expect(find.text('Tu actividad'), findsOneWidget);
    expect(find.byType(ManoProjectFilterTabs), findsOneWidget);
    final tabs = tester.widget<ManoProjectFilterTabs>(
      find.byType(ManoProjectFilterTabs),
    );
    expect(tabs.labels, ['Pendientes', 'En curso', 'Historial']);
    expect(find.text('Servicios'), findsNothing);
    expect(find.text('Proyectos'), findsNothing);
  });

  testWidgets('Pendientes mixes pending requests and open projects', (
    tester,
  ) async {
    await _tall(tester);
    await pumpRouterAt(tester, '/projects');

    expect(_card('activity-request-request-1'), findsOneWidget);
    expect(find.text('Pendiente'), findsWidgets);
    expect(_card('activity-request-request-3'), findsNothing);
    await tester.scrollUntilVisible(
      _card('project-card-project-2'),
      300,
      scrollable: _list,
    );
    expect(_card('project-card-project-1'), findsOneWidget);
    expect(_card('project-card-project-3'), findsNothing);
  });

  testWidgets('each filter lists its own items, newest first', (tester) async {
    await _tall(tester);
    await pumpRouterAt(tester, '/projects');

    // The mocks stamp each request as it is seeded, so the last is newest.
    expect(_order(tester), [
      'activity-request-request-8',
      'activity-request-request-7',
      'activity-request-request-6',
      'activity-request-request-2',
      'activity-request-request-1',
      'project-card-project-1',
      'project-card-project-2',
    ]);

    await tester.tap(find.text('En curso'));
    await tester.pumpAndSettle();
    expect(_order(tester), [
      'activity-job-job-2',
      'activity-job-job-1',
      'activity-job-job-3',
      'activity-job-job-4',
      'project-card-project-3',
    ]);

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(
      _order(tester),
      unorderedEquals([
        'activity-request-request-4',
        'activity-request-request-5',
        'activity-job-job-6',
        'activity-job-job-5',
        'project-card-project-4',
      ]),
    );
    expect(
      _order(tester).indexOf('activity-job-job-6'),
      lessThan(_order(tester).indexOf('activity-job-job-5')),
    );
  });

  testWidgets('a job card shows title, provider, date, price and status', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/projects');
    await tester.tap(find.text('En curso'));
    await tester.pumpAndSettle();

    final card = tester.widget<ManoProjectCard>(_card('activity-job-job-1'));
    expect(card.title, 'Limpieza profunda del hogar');
    expect(card.professionalName, 'Andrés Castro');
    expect(card.scheduledLabel, ManoFormat.dateTime(mockJobStart(2, 9)));
    expect(card.priceLabel, r'$120.000');
    expect(card.statusLabel, 'Programado');

    final hourly = tester.widget<ManoProjectCard>(_card('activity-job-job-2'));
    expect(hourly.priceLabel, r'$45.000/hora');
  });

  testWidgets('a project card says where it stands', (tester) async {
    await _tall(tester);
    await pumpRouterAt(tester, '/projects');

    final quoted = tester.widget<ManoProjectSummaryCard>(
      _card('project-card-project-1'),
    );
    expect(quoted.title, 'Pintar apartamento de 70 m²');
    expect(quoted.subtitle, startsWith('Pintura · hace'));
    expect(quoted.statusLabel, '3 cotizaciones');
    expect(quoted.trailingLabel, r'desde $1.450.000');
    expect(
      tester
          .widget<ManoProjectSummaryCard>(_card('project-card-project-2'))
          .statusLabel,
      'Esperando cotizaciones',
    );

    await tester.tap(find.text('En curso'));
    await tester.pumpAndSettle();
    final awarded = tester.widget<ManoProjectSummaryCard>(
      _card('project-card-project-3'),
    );
    expect(awarded.statusLabel, 'Elegiste a Andrés Castro');
    expect(awarded.trailingLabel, r'$580.000');
  });

  testWidgets('every filter has an empty state', (tester) async {
    await pumpRouterAt(tester, '/projects', overrides: emptyActivity());

    const messages = {
      'Pendientes': 'No tienes nada pendiente.',
      'En curso': 'Nada está en curso ahora.',
      'Historial': 'Aún no tienes historial.',
    };
    for (final MapEntry(key: filter, value: message) in messages.entries) {
      await tester.tap(find.text(filter));
      await tester.pumpAndSettle();
      expect(find.byType(ManoEmptyState), findsOneWidget, reason: filter);
      expect(find.text(message), findsOneWidget, reason: filter);
      expect(_card('publish-project-pill'), findsOneWidget, reason: filter);
    }
  });

  testWidgets('a failed load shows an error with retry', (tester) async {
    await pumpRouterAt(tester, '/projects', overrides: failingActivity());

    expect(find.text('No pudimos cargar tu actividad.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('failing projects alone fail the list too', (tester) async {
    await pumpRouterAt(
      tester,
      '/projects',
      overrides: [
        projectRepositoryProvider.overrideWithValue(FakeProjects(fails: true)),
      ],
    );

    expect(find.text('No pudimos cargar tu actividad.'), findsOneWidget);
  });

  testWidgets('tapping a job card opens its detail', (tester) async {
    final c = await pumpRouterAt(tester, '/projects');
    await tester.tap(find.text('En curso'));
    await tester.pumpAndSettle();

    await tester.tap(_card('activity-job-job-2'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/projects/job/job-2');
  });

  testWidgets('tapping a project card opens the project', (tester) async {
    final c = await pumpRouterAt(tester, '/projects');
    await tester.scrollUntilVisible(
      _card('project-card-project-1'),
      300,
      scrollable: _list,
    );

    await tester.tap(_card('project-card-project-1'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/projects/project/project-1');
  });

  testWidgets('a pending request can be cancelled from its sheet', (
    tester,
  ) async {
    await _tall(tester);
    await pumpRouterAt(tester, '/projects');

    await tester.tap(_card('activity-request-request-1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Acabamos de mudarnos'), findsOneWidget);

    await tester.tap(find.text('Cancelar solicitud'));
    await tester.pumpAndSettle();

    expect(find.text('Cancelamos tu solicitud.'), findsOneWidget);
    expect(_card('activity-request-request-1'), findsNothing);
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(_card('activity-request-request-1'), findsOneWidget);
  });

  testWidgets('a cancelled job card says only Cancelado', (tester) async {
    await pumpRouterAt(tester, '/projects');
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    final card = tester.widget<ManoProjectCard>(_card('activity-job-job-6'));
    expect(card.statusLabel, 'Cancelado');
  });

  testWidgets('a closed request sheet offers no cancel', (tester) async {
    await pumpRouterAt(tester, '/projects');
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    await tester.tap(_card('activity-request-request-4'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No tengo disponibilidad esa semana.'),
      findsOneWidget,
    );
    expect(find.text('Cancelar solicitud'), findsNothing);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoPromptSheet), findsNothing);
  });
}
