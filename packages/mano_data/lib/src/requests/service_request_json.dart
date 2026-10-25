import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_json.dart';
import '../gateway/offer_json.dart';
import '../gateway/service_lookup.dart';

/// The `ServiceRequest` selection every adapter asks for.
const serviceRequestFields =
    'id client { id } offer { $offerFields } message proposedStart status '
    'rejectionReason createdAt';

/// Maps a gateway `ServiceRequest`; [service] supplies its title and category.
ServiceRequest serviceRequestFromJson(
  Map<String, dynamic> json,
  JobService? service,
) {
  final offer = offerFromJson(json['offer'] as Map<String, dynamic>);
  final proposedStart = json['proposedStart'];
  return ServiceRequest(
    id: json['id'] as String,
    offer: offer,
    serviceTitle: service?.title ?? '',
    category: service?.category ?? '',
    client: partyFromId(
      (json['client'] as Map<String, dynamic>)['id'] as String,
    ),
    provider: partyFromId(offer.offerantId),
    message: json['message'] as String? ?? '',
    proposedStart: proposedStart == null
        ? null
        : dateTimeFromJson(proposedStart),
    status: switch (json['status']) {
      'ACCEPTED' => ServiceRequestStatus.accepted,
      'REJECTED' => ServiceRequestStatus.rejected,
      'CANCELLED' => ServiceRequestStatus.cancelled,
      _ => ServiceRequestStatus.pending,
    },
    rejectionReason: json['rejectionReason'] as String?,
    createdAt: dateTimeFromJson(json['createdAt']),
  );
}

/// Maps a gateway `ServiceRequest`, looking its service up through [services].
Future<ServiceRequest> enrichedServiceRequest(
  Map<String, dynamic> json,
  ServiceLookup services,
) async =>
    serviceRequestFromJson(json, await services(offeredServiceIdOf(json)));

/// The gateway spelling of a request status.
String serviceRequestStatusToJson(ServiceRequestStatus status) =>
    status.name.toUpperCase();
