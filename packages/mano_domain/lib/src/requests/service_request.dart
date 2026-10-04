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
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id, offer, serviceTitle, client, provider, message, proposedStart,
    status, rejectionReason, createdAt,
  );

  @override
  String toString() => 'ServiceRequest($id, $status)';
}
