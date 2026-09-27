import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/screens/projects_tab_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// A fixed, in-memory project list covering every status, so the filter
/// tests have something to prove against.
final class _FakeProjectRepository implements ProjectRepository {
  const _FakeProjectRepository(this._projects);

  final List<Project> _projects;

  @override
  Future<List<Project>> projects() async => _projects;
}

final _fakeProjects = [
  Project(
    id: 'proj-1',
    title: 'Limpieza profunda de apartamento',
    professionalName: 'Carlos Mendoza',
    professionalPhotoUrl: 'https://example.com/carlos.jpg',
    status: ProjectStatus.scheduled,
    scheduledAt: DateTime(2026, 3, 12, 15, 0),
    address: 'Cra 5 No. 12-34, Chapinero, Bogotá',
    priceCents: 8000000,
  ),
  Project(
    id: 'proj-2',
    title: 'Reparación de tuberías en cocina',
    professionalName: 'Juan García',
    professionalPhotoUrl: 'https://example.com/juan.jpg',
    status: ProjectStatus.inProgress,
    scheduledAt: DateTime(2026, 9, 29, 14, 0),
    address: 'Cll 72 No. 8-45, Usaquén, Bogotá',
    priceCents: 7500000,
  ),
  Project(
    id: 'proj-3',
    title: 'Instalación de nuevos puntos eléctricos',
    professionalName: 'Roberto López',
    professionalPhotoUrl: 'https://example.com/roberto.jpg',
    status: ProjectStatus.completed,
    scheduledAt: DateTime(2026, 8, 10, 9, 30),
    address: 'Cra 11 No. 85-20, Suba, Bogotá',
    priceCents: 9500000,
  ),
  Project(
    id: 'proj-4',
    title: 'Pintura interior de sala y comedor',
    professionalName: 'Miguel Rodríguez',
    professionalPhotoUrl: 'https://example.com/miguel.jpg',
    status: ProjectStatus.canceled,
    scheduledAt: DateTime(2026, 7, 20, 11, 0),
    address: 'Cll 45 No. 15-67, Teusaquillo, Bogotá',
    priceCents: 6500000,
  ),
];

Future<void> _host(WidgetTester tester, {List<Project>? projects}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectRepositoryProvider.overrideWithValue(
          _FakeProjectRepository(projects ?? _fakeProjects),
        ),
      ],
      child: MaterialApp(
        theme: ManoTheme.light(),
        home: const ProjectsTabScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders every project title when "Todos" is selected', (
    tester,
  ) async {
    await _host(tester);

    expect(find.text('Limpieza profunda de apartamento'), findsOneWidget);
    expect(find.text('Reparación de tuberías en cocina'), findsOneWidget);
    expect(
      find.text('Instalación de nuevos puntos eléctricos'),
      findsOneWidget,
    );
    expect(find.text('Pintura interior de sala y comedor'), findsOneWidget);
  });

  testWidgets(
    'tapping the "Programados" filter shows only scheduled projects',
    (tester) async {
      await _host(tester);

      await tester.tap(find.text('Programados'));
      await tester.pumpAndSettle();

      expect(find.text('Limpieza profunda de apartamento'), findsOneWidget);
      expect(find.text('Reparación de tuberías en cocina'), findsNothing);
      expect(
        find.text('Instalación de nuevos puntos eléctricos'),
        findsNothing,
      );
      expect(find.text('Pintura interior de sala y comedor'), findsNothing);
    },
  );

  testWidgets('tapping a project card shows the stub notice', (tester) async {
    await _host(tester);

    await tester.tap(find.byType(ManoProjectCard).first);
    await tester.pumpAndSettle();

    expect(find.text('Muy pronto'), findsOneWidget);
  });

  testWidgets('renders the empty state when there are no projects', (
    tester,
  ) async {
    await _host(tester, projects: []);

    expect(find.byType(ManoEmptyState), findsOneWidget);
    expect(find.text('Aún no has solicitado ningún servicio'), findsOneWidget);
    expect(find.text('Solicita tu primer servicio'), findsOneWidget);
  });

  testWidgets('tapping the empty state CTA shows the stub notice', (
    tester,
  ) async {
    await _host(tester, projects: []);

    await tester.tap(find.text('Solicita tu primer servicio'));
    await tester.pumpAndSettle();

    expect(find.text('Muy pronto'), findsOneWidget);
  });

  testWidgets(
    'shows a filter-specific empty message (not the "never requested a service" one) when the user has projects but none match the selected filter',
    (tester) async {
      // Only scheduled projects -- "Cancelados" will match none of them,
      // even though the user plainly has requested service before.
      final onlyScheduled = _fakeProjects
          .where((project) => project.status == ProjectStatus.scheduled)
          .toList();
      await _host(tester, projects: onlyScheduled);

      final cancelTab = find.text('Cancelados');
      await tester.ensureVisible(cancelTab);
      await tester.pumpAndSettle();
      await tester.tap(cancelTab);
      await tester.pumpAndSettle();

      expect(
        find.text('Aún no has solicitado ningún servicio'),
        findsNothing,
      );
      expect(find.text('Solicita tu primer servicio'), findsNothing);
      expect(find.text('No hay proyectos en esta categoría.'), findsOneWidget);
    },
  );
}
