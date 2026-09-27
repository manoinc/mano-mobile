import 'package:mano_data/src/projects/mock_project_repository.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('MockProjectRepository', () {
    late MockProjectRepository repository;

    setUp(() {
      repository = const MockProjectRepository();
    });

    test('projects() returns a non-empty list', () async {
      final projects = await repository.projects();
      expect(projects, isNotEmpty);
    });

    test('every ProjectStatus enum value appears at least once', () async {
      final projects = await repository.projects();
      final statuses = {for (final p in projects) p.status};

      for (final status in ProjectStatus.values) {
        expect(statuses.contains(status), isTrue,
            reason: 'Status $status not found in projects');
      }
    });
  });
}
