import '../catalog/service_offer.dart';
import '../shared/party.dart';

enum ServiceRequestStatus { pending, accepted, rejected, cancelled }

/// A requester asking a provider for work, before it becomes a [Job].
final class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.offer,
    required this.serviceTitle,
    required this.client,
    required this.provider,
    required this.message,
    required this.status,
    required this.createdAt,
    this.proposedStart,
    this.rejectionReason,
    this.category = '',
    this.neighborhood = '',
    this.photoUrls = const [],
  });

  final String id;
  final ServiceOffer offer;
  final String serviceTitle;
  final Party client;
  final Party provider;
  final String message;
  final DateTime? proposedStart;
  final ServiceRequestStatus status;
  final String? rejectionReason;
  final DateTime createdAt;

  /// Canonical [ServiceCategories] id; empty when unknown.
  final String category;

  /// Where the job is, as the client names it; empty when not given.
  final String neighborhood;
  final List<String> photoUrls;

  bool get hasPhotos => photoUrls.isNotEmpty;

  bool get canRespond => status == ServiceRequestStatus.pending;

  bool get canCancel => status == ServiceRequestStatus.pending;

  ServiceRequest copyWith({
    ServiceRequestStatus? status,
    String? rejectionReason,
  }) => ServiceRequest(
    id: id,
    offer: offer,
    serviceTitle: serviceTitle,
    client: client,
    provider: provider,
    message: message,
    proposedStart: proposedStart,
    status: status ?? this.status,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    createdAt: createdAt,
    category: category,
    neighborhood: neighborhood,
    photoUrls: photoUrls,
  );

  @override
  bool operator ==(Object other) =>
      other is ServiceRequest &&
      other.id == id &&
      other.offer == offer &&
      other.serviceTitle == serviceTitle &&
      other.client == client &&
      other.provider == provider &&
      other.message == message &&
      other.proposedStart == proposedStart &&
      other.status == status &&
      other.rejectionReason == rejectionReason &&
      other.createdAt == createdAt &&
      other.category == category &&
      other.neighborhood == neighborhood &&
      _sameList(other.photoUrls, photoUrls);

  @override
  int get hashCode => Object.hash(
    id,
    offer,
    serviceTitle,
    client,
    provider,
    message,
    proposedStart,
    status,
    rejectionReason,
    createdAt,
    category,
    neighborhood,
    Object.hashAll(photoUrls),
  );

  @override
  String toString() => 'ServiceRequest($id, $status)';

  static bool _sameList(List<String> a, List<String> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((e) => e);
}
