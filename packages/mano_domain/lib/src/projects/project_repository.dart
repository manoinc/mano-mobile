import 'project.dart';

abstract interface class ProjectRepository {
  Future<List<Project>> projects();
}
