final class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.label,
    required this.iconKey,
  });

  final String id;
  final String label; // display name, e.g. "Limpieza"
  final String iconKey; // opaque key an IconData lookup maps, e.g. "cleaning" -- this package cannot reference IconData

  @override
  bool operator ==(Object other) =>
      other is ServiceCategory &&
      other.id == id &&
      other.label == label &&
      other.iconKey == iconKey;

  @override
  int get hashCode => Object.hash(id, label, iconKey);

  @override
  String toString() => 'ServiceCategory($id, $label)';
}
