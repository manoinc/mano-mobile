import 'package:mano_domain/mano_domain.dart';

final class MockProjectRepository implements ProjectRepository {
  const MockProjectRepository();

  static final List<Project> _projects = [
    Project(
      id: 'proj-1',
      title: 'Limpieza profunda de apartamento',
      professionalName: 'Carlos Mendoza',
      professionalPhotoUrl: 'https://i.pravatar.cc/150?u=carlos-mendoza',
      status: ProjectStatus.scheduled,
      scheduledAt: DateTime(2026, 10, 15, 10, 0),
      address: 'Cra 5 No. 12-34, Chapinero, Bogotá',
      priceCents: 8000000,
    ),
    Project(
      id: 'proj-2',
      title: 'Reparación de tuberías en cocina',
      professionalName: 'Juan García',
      professionalPhotoUrl: 'https://i.pravatar.cc/150?u=juan-garcia',
      status: ProjectStatus.inProgress,
      scheduledAt: DateTime(2026, 9, 25, 14, 0),
      address: 'Cll 72 No. 8-45, Usaquén, Bogotá',
      priceCents: 7500000,
    ),
    Project(
      id: 'proj-3',
      title: 'Instalación de nuevos puntos eléctricos',
      professionalName: 'Roberto López',
      professionalPhotoUrl: 'https://i.pravatar.cc/150?u=roberto-lopez',
      status: ProjectStatus.completed,
      scheduledAt: DateTime(2026, 8, 10, 9, 30),
      address: 'Cra 11 No. 85-20, Suba, Bogotá',
      priceCents: 9500000,
    ),
    Project(
      id: 'proj-4',
      title: 'Pintura interior de sala y comedor',
      professionalName: 'Miguel Rodríguez',
      professionalPhotoUrl: 'https://i.pravatar.cc/150?u=miguel-rodriguez',
      status: ProjectStatus.canceled,
      scheduledAt: DateTime(2026, 7, 20, 11, 0),
      address: 'Cll 45 No. 15-67, Teusaquillo, Bogotá',
      priceCents: 6500000,
    ),
    Project(
      id: 'proj-5',
      title: 'Mantenimiento de jardín frontal',
      professionalName: 'Diego Morales',
      professionalPhotoUrl: 'https://i.pravatar.cc/150?u=diego-morales',
      status: ProjectStatus.scheduled,
      scheduledAt: DateTime(2026, 10, 20, 15, 0),
      address: 'Cra 7 No. 125-45, Barrio Lago, Bogotá',
      priceCents: 5500000,
    ),
  ];

  @override
  Future<List<Project>> projects() async => _projects;
}
