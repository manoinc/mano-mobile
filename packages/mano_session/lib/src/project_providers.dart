import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

/// The composition step that matters: an adapter bound to the domain's port.
final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => const MockProjectRepository(),
);

final projectsProvider = FutureProvider<List<Project>>(
  (ref) => ref.watch(projectRepositoryProvider).projects(),
);
