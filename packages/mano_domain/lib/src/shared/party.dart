/// Someone on either side of a request or job, as the other side sees them.
final class Party {
  const Party({
    required this.id,
    required this.displayName,
    required this.photoUrl,
  });

  final String id;
  final String displayName;
  final String photoUrl;

  /// The name to show; [fallback] while the profile has none yet.
  String nameOr(String fallback) =>
      displayName.trim().isEmpty ? fallback : displayName;

  @override
  bool operator ==(Object other) =>
      other is Party &&
      other.id == id &&
      other.displayName == displayName &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(id, displayName, photoUrl);

  @override
  String toString() => 'Party($id, $displayName)';
}
