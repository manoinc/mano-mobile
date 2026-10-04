import '../result.dart';
import '../shared/data_failure.dart';
import 'service_request.dart';

/// Requests the signed-in user sent (requester) or received (provider).
abstract interface class ServiceRequestRepository {
  Future<List<ServiceRequest>> mine({ServiceRequestStatus? status});

  Future<Result<ServiceRequest, DataFailure>> request(
    String offerId, {
    required String message,
    DateTime? proposedStart,
  });

  Future<Result<ServiceRequest, DataFailure>> accept(String id);

  Future<Result<ServiceRequest, DataFailure>> reject(String id, {String? reason});

  Future<Result<ServiceRequest, DataFailure>> cancel(String id);
}
