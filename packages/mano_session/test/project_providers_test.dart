import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

/// Tests the project providers with a fake repository and nothing else.

final class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository({this.onProjects});

  final Future<List<Project>> Function()? onProjects;

  @override
  Future<List<Project>> projects() async => onProjects?.call() ?? const [];
}

final _project = Project(
  id: 'test-project',
  title: 'Test Project',
  professionalName: 'Test Professional',
  professionalPhotoUrl: 'https://example.com/photo.jpg',
  status: ProjectStatus.scheduled,
  scheduledAt: DateTime(2026, 10, 15, 10, 0),
  address: 'Test Address',
  priceCents: 100000,
);

ProviderContainer containerWith(ProjectRepository repository) {
  final container = ProviderContainer.test(
    overrides: [projectRepositoryProvider.overrideWithValue(repository)],
  );
  return container;
}

void main() {
  test('projectsProvider resolves to the fake projects list', () async {
    final container = containerWith(
      _FakeProjectRepository(
        onProjects: () async => [_project],
      ),
    );

    final projects = await container.read(projectsProvider.future);

    expect(projects, [_project]);
  });

  test('projectsProvider resolves to empty list when overridden', () async {
    final container = containerWith(
      _FakeProjectRepository(onProjects: () async => []),
    );

    final projects = await container.read(projectsProvider.future);

    expect(projects, isEmpty);
  });
}
