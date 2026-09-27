import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Project', () {
    test('two projects with different field values are unequal', () {
      final project1 = Project(
        id: 'proj1',
        title: 'Limpieza de casa',
        professionalName: 'Juan',
        professionalPhotoUrl: 'https://example.com/photo1.jpg',
        status: ProjectStatus.scheduled,
        scheduledAt: DateTime(2026, 1, 1, 10),
        address: 'Calle 1',
        priceCents: 10000,
        currency: 'COP',
      );
      final project2 = Project(
        id: 'proj2',
        title: 'Reparación de plomería',
        professionalName: 'María',
        professionalPhotoUrl: 'https://example.com/photo2.jpg',
        status: ProjectStatus.inProgress,
        scheduledAt: DateTime(2026, 1, 2, 10),
        address: 'Calle 2',
        priceCents: 20000,
        currency: 'COP',
      );

      expect(project1 == project2, isFalse);
    });

    test('two projects with identical field values are equal and share a hashCode', () {
      final scheduledAt = DateTime(2026, 1, 1, 10);
      final project1 = Project(
        id: 'proj1',
        title: 'Limpieza de casa',
        professionalName: 'Juan',
        professionalPhotoUrl: 'https://example.com/photo1.jpg',
        status: ProjectStatus.scheduled,
        scheduledAt: scheduledAt,
        address: 'Calle 1',
        priceCents: 10000,
        currency: 'COP',
      );
      final project2 = Project(
        id: 'proj1',
        title: 'Limpieza de casa',
        professionalName: 'Juan',
        professionalPhotoUrl: 'https://example.com/photo1.jpg',
        status: ProjectStatus.scheduled,
        scheduledAt: scheduledAt,
        address: 'Calle 1',
        priceCents: 10000,
        currency: 'COP',
      );

      expect(project1 == project2, isTrue);
      expect(project1.hashCode == project2.hashCode, isTrue);
    });

    test('toString is non-empty and mentions the id', () {
      final project = Project(
        id: 'proj1',
        title: 'Limpieza de casa',
        professionalName: 'Juan',
        professionalPhotoUrl: 'https://example.com/photo1.jpg',
        status: ProjectStatus.scheduled,
        scheduledAt: DateTime(2026, 1, 1, 10),
        address: 'Calle 1',
        priceCents: 10000,
      );

      expect(project.toString(), isNotEmpty);
      expect(project.toString(), contains('proj1'));
    });
  });

  group('ProjectStatus', () {
    test('every status value is reachable', () {
      const statuses = <ProjectStatus>[
        ProjectStatus.scheduled,
        ProjectStatus.inProgress,
        ProjectStatus.completed,
        ProjectStatus.canceled,
      ];

      for (final status in statuses) {
        final isReachable = switch (status) {
          ProjectStatus.scheduled => true,
          ProjectStatus.inProgress => true,
          ProjectStatus.completed => true,
          ProjectStatus.canceled => true,
        };

        expect(isReachable, isTrue, reason: '$status');
      }
    });
  });
}
