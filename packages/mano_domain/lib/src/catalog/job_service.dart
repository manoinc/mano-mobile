/// A kind of work in the catalog, e.g. "Limpieza profunda".
final class JobService {
  const JobService({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
  });

  final String id;
  final String category;
  final String title;
  final String description;

  @override
  bool operator ==(Object other) =>
      other is JobService &&
      other.id == id &&
      other.category == category &&
      other.title == title &&
      other.description == description;

  @override
  int get hashCode => Object.hash(id, category, title, description);

  @override
  String toString() => 'JobService($id, $title)';
}
