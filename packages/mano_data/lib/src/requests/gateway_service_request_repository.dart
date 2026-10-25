import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_json.dart';
import '../gateway/gateway_transport.dart';
import '../gateway/service_lookup.dart';
import 'service_request_json.dart';

/// [ServiceRequestRepository] on the gateway; titles and categories come from the catalog.
final class GatewayServiceRequestRepository
    implements ServiceRequestRepository {
  GatewayServiceRequestRepository(this._transport, ServiceCatalog catalog)
    : _services = ServiceLookup(catalog);

  final GatewayTransport _transport;
  final ServiceLookup _services;

  static const _mineQuery =
      '''
query MyServiceRequests(\$status: ServiceRequestStatus) {
  myServiceRequests(status: \$status, page: {first: 50}) {
    items { $serviceRequestFields }
  }
}''';

  static const _requestMutation =
      '''
mutation RequestService(\$offerId: ID!, \$input: ServiceRequestInput!) {
  requestService(offerId: \$offerId, input: \$input) { $serviceRequestFields }
}''';

  static const _acceptMutation =
      '''
mutation Accept(\$id: ID!) {
  acceptServiceRequest(id: \$id) { $serviceRequestFields }
}''';

  static const _rejectMutation =
      '''
mutation Reject(\$id: ID!, \$reason: String) {
  rejectServiceRequest(id: \$id, reason: \$reason) { $serviceRequestFields }
}''';

  static const _cancelMutation =
      '''
mutation Cancel(\$id: ID!) {
  cancelServiceRequest(id: \$id) { $serviceRequestFields }
}''';

  @override
  Future<List<ServiceRequest>> mine({ServiceRequestStatus? status}) async {
    final data = await _transport.run(
      _mineQuery,
      variables: {
        'status': status == null ? null : serviceRequestStatusToJson(status),
      },
    );
    return Future.wait(pageItems(data['myServiceRequests']).map(_enrich));
  }

  @override
  Future<Result<ServiceRequest, DataFailure>> request(
    String offerId, {
    required String message,
    DateTime? proposedStart,
  }) => _mutate(_requestMutation, 'requestService', {
    'offerId': offerId,
    'input': {
      'message': message,
      'proposedStart': proposedStart == null
          ? null
          : dateTimeToJson(proposedStart),
    },
  });

  @override
  Future<Result<ServiceRequest, DataFailure>> accept(String id) =>
      _mutate(_acceptMutation, 'acceptServiceRequest', {'id': id});

  @override
  Future<Result<ServiceRequest, DataFailure>> reject(
    String id, {
    String? reason,
  }) => _mutate(_rejectMutation, 'rejectServiceRequest', {
    'id': id,
    'reason': reason,
  });

  @override
  Future<Result<ServiceRequest, DataFailure>> cancel(String id) =>
      _mutate(_cancelMutation, 'cancelServiceRequest', {'id': id});

  Future<Result<ServiceRequest, DataFailure>> _mutate(
    String document,
    String field,
    Map<String, Object?> variables,
  ) => guardGateway(() async {
    final data = await _transport.run(document, variables: variables);
    return _enrich(data[field] as Map<String, dynamic>);
  });

  Future<ServiceRequest> _enrich(Map<String, dynamic> json) =>
      enrichedServiceRequest(json, _services);
}
