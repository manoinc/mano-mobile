import 'project_status.dart';

final class Project {
  const Project({
    required this.id,
    required this.title,
    required this.professionalName,
    required this.professionalPhotoUrl,
    required this.status,
    required this.scheduledAt,
    required this.address,
    required this.priceCents,
    this.currency = 'COP',
  });

  final String id;
  final String title;
  final String professionalName;
  final String professionalPhotoUrl;
  final ProjectStatus status;
  final DateTime scheduledAt;
  final String address;
  final int priceCents;
  final String currency;

  @override
  bool operator ==(Object other) =>
      other is Project &&
      other.id == id &&
      other.title == title &&
      other.professionalName == professionalName &&
      other.professionalPhotoUrl == professionalPhotoUrl &&
      other.status == status &&
      other.scheduledAt == scheduledAt &&
      other.address == address &&
      other.priceCents == priceCents &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(
        id, title, professionalName, professionalPhotoUrl, status,
        scheduledAt, address, priceCents, currency,
      );

  @override
  String toString() => 'Project($id, $title, $status)';
}
