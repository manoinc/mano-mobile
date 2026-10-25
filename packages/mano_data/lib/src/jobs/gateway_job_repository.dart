import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_json.dart';
import '../gateway/gateway_transport.dart';
import '../gateway/service_lookup.dart';
import '../requests/service_request_json.dart';
import 'job_json.dart';

/// [JobRepository] on the gateway; titles come from the catalog.
final class GatewayJobRepository implements JobRepository {
  GatewayJobRepository(this._transport, ServiceCatalog catalog)
    : _services = ServiceLookup(catalog);

  final GatewayTransport _transport;
  final ServiceLookup _services;

  static const _mineQuery =
      '''
query MyJobs(\$status: JobStatus) {
  myJobs(status: \$status, page: {first: 50}) { items { $jobFields } }
}''';

  static const _jobQuery = '''
query Job(\$id: ID!) { job(id: \$id) { $jobFields } }''';

  static const _bookSlotMutation =
      '''
mutation BookSlot(\$offerId: ID!, \$slotStart: DateTime!) {
  bookSlot(offerId: \$offerId, slotStart: \$slotStart) { $jobFields }
}''';

  static const _startMutation = '''
mutation Start(\$id: ID!) { startJob(id: \$id) { $jobFields } }''';

  static const _finishMutation =
      '''
mutation Finish(\$id: ID!, \$actualHours: Decimal) {
  finishJob(id: \$id, actualHours: \$actualHours) { $jobFields }
}''';

  static const _cancelMutation =
      '''
mutation Cancel(\$id: ID!, \$reason: String) {
  cancelJob(id: \$id, reason: \$reason) { $jobFields }
}''';

  static const _rebookMutation =
      '''
mutation Rebook(\$jobId: ID!) {
  rebook(jobId: \$jobId) { $serviceRequestFields }
}''';

  @override
  Future<List<Job>> mine({JobStatus? status}) async {
    final data = await _transport.run(
      _mineQuery,
      variables: {'status': status == null ? null : jobStatusToJson(status)},
    );
    return Future.wait(pageItems(data['myJobs']).map(_enrich));
  }

  @override
  Future<Job?> job(String id) async {
    final result = await guardGateway(() async {
      final data = await _transport.run(_jobQuery, variables: {'id': id});
      return _enrich(data['job'] as Map<String, dynamic>);
    });
    return switch (result) {
      Ok(:final value) => value,
      Err(failure: DataNotFound()) => null,
      Err(:final failure) => throw failure,
    };
  }

  @override
  Future<Result<Job, DataFailure>> bookSlot(
    String offerId,
    DateTime slotStart,
  ) => _mutate(_bookSlotMutation, 'bookSlot', {
    'offerId': offerId,
    'slotStart': dateTimeToJson(slotStart),
  });

  @override
  Future<Result<Job, DataFailure>> start(String id) =>
      _mutate(_startMutation, 'startJob', {'id': id});

  @override
  Future<Result<Job, DataFailure>> finish(String id, {double? actualHours}) =>
      _mutate(_finishMutation, 'finishJob', {
        'id': id,
        'actualHours': actualHours,
      });

  @override
  Future<Result<Job, DataFailure>> cancel(String id, {String? reason}) =>
      _mutate(_cancelMutation, 'cancelJob', {'id': id, 'reason': reason});

  @override
  Future<Result<ServiceRequest, DataFailure>> rebook(String jobId) =>
      guardGateway(() async {
        final data = await _transport.run(
          _rebookMutation,
          variables: {'jobId': jobId},
        );
        return enrichedServiceRequest(
          data['rebook'] as Map<String, dynamic>,
          _services,
        );
      });

  Future<Result<Job, DataFailure>> _mutate(
    String document,
    String field,
    Map<String, Object?> variables,
  ) => guardGateway(() async {
    final data = await _transport.run(document, variables: variables);
    return _enrich(data[field] as Map<String, dynamic>);
  });

  Future<Job> _enrich(Map<String, dynamic> json) =>
      enrichedJob(json, _services);
}
