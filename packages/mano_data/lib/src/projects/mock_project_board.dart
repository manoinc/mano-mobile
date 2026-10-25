import 'package:mano_domain/mano_domain.dart';

import 'mock_project_seeds.dart';

/// The in-memory projects service both mock repositories share.
///
/// Holds every project with all its quotes; each repository shows its own view.
final class MockProjectBoard {
  MockProjectBoard({DateTime Function()? now}) : now = now ?? DateTime.now {
    for (final seed in mockProjectSeeds(this.now())) {
      projects.add(seed.project);
      owners[seed.project.id] = seed.ownerId;
    }
  }

  final DateTime Function() now;

  /// Newest first, quotes always filled.
  final List<Project> projects = [];

  /// Project id to the requester who published it.
  final Map<String, String> owners = {};

  int _nextId = 100;

  String nextId(String prefix) => '$prefix-${_nextId++}';

  Project? byId(String id) => _at(projects.indexWhere((p) => p.id == id));

  /// The project holding [quoteId], if any.
  Project? holding(String quoteId) =>
      _at(projects.indexWhere((p) => p.quotes!.any((q) => q.id == quoteId)));

  void replace(Project project) =>
      projects[projects.indexWhere((p) => p.id == project.id)] = project;

  Project? _at(int index) => index < 0 ? null : projects[index];
}
