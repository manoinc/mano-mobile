import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/projects/my_projects_list.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';
import 'projects_fakes.dart';

Future<void> _openProjects(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(ManoProjectFilterTabs).first,
      matching: find.text('Proyectos'),
    ),
  );
  await tester.pumpAndSettle();
}

ManoProjectSummaryCard _card(WidgetTester tester, String id) =>
    tester.widget<ManoProjectSummaryCard>(find.byKey(Key('project-card-$id')));

void main() {
  testWidgets('Actividad opens on Servicios, with Proyectos beside it', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/projects');

    expect(find.text('Servicios'), findsOneWidget);
    expect(find.byType(ManoProjectSummaryCard), findsNothing);
  });

  testWidgets('each project card says where it stands', (tester) async {
    await pumpRouterAt(tester, '/projects');
    await _openProjects(tester);

    final quoted = _card(tester, 'project-1');
    expect(quoted.title, 'Pintar apartamento de 70 m²');
    expect(quoted.subtitle, startsWith('Pintura · hace'));
    expect(quoted.statusLabel, '3 cotizaciones');
    expect(quoted.trailingLabel, r'desde $1.450.000');

    expect(_card(tester, 'project-2').statusLabel, 'Esperando cotizaciones');
    await tester.scrollUntilVisible(
      find.byKey(const Key('project-card-project-4')),
      200,
      scrollable: find.descendant(
        of: find.byType(MyProjectsList),
        matching: find.byType(Scrollable),
      ),
    );
    expect(_card(tester, 'project-3').statusLabel, 'Elegiste a Andrés Castro');
    expect(_card(tester, 'project-3').trailingLabel, r'$580.000');
    expect(_card(tester, 'project-4').statusLabel, 'Cancelado');
  });

  testWidgets('a card opens its project', (tester) async {
    final container = await pumpRouterAt(tester, '/projects');
    await _openProjects(tester);

    await tester.tap(find.byKey(const Key('project-card-project-1')));
    await tester.pumpAndSettle();

    expect(routerPath(container), '/projects/project/project-1');
  });

  testWidgets('the segment can be linked to', (tester) async {
    await pumpRouterAt(tester, '/projects?segment=proyectos');

    expect(find.byKey(const Key('project-card-project-1')), findsOneWidget);
  });

  testWidgets('a guest is asked to sign in before publishing', (tester) async {
    await pumpRouterAt(tester, '/projects?segment=proyectos');

    await tester.tap(find.text('Publicar proyecto'));
    await tester.pumpAndSettle();

    expect(find.text('Necesitas una cuenta'), findsOneWidget);
  });

  testWidgets('with an account, the pill opens the publish flow', (
    tester,
  ) async {
    final container = await pumpRouterAt(
      tester,
      '/projects?segment=proyectos',
      session: signedIn(),
    );

    await tester.tap(find.text('Publicar proyecto'));
    await tester.pumpAndSettle();

    expect(routerPath(container), '/publish');
  });

  testWidgets('no projects yet invites publishing one', (tester) async {
    await pumpRouterAt(
      tester,
      '/projects?segment=proyectos',
      overrides: [projectRepositoryProvider.overrideWithValue(FakeProjects())],
    );

    expect(find.byType(ManoEmptyState), findsOneWidget);
    expect(find.text('Aún no has publicado proyectos.'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    await pumpRouterAt(
      tester,
      '/projects?segment=proyectos',
      overrides: [
        projectRepositoryProvider.overrideWithValue(FakeProjects(fails: true)),
      ],
    );

    expect(find.text('No pudimos cargar tus proyectos.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
