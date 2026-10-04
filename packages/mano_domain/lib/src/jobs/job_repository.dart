import '../requests/service_request.dart';
import '../result.dart';
import '../shared/data_failure.dart';
import 'job.dart';

/// Jobs the signed-in user hired (requester) or works (provider).
abstract interface class JobRepository {
  Future<List<Job>> mine({JobStatus? status});

  /// Null when no such job exists.
  Future<Job?> job(String id);

  Future<Result<Job, DataFailure>> bookSlot(String offerId, DateTime slotStart);

  Future<Result<Job, DataFailure>> start(String id);

  /// [actualHours] is required for hourly jobs.
  Future<Result<Job, DataFailure>> finish(String id, {double? actualHours});

  Future<Result<Job, DataFailure>> cancel(String id, {String? reason});

  Future<Result<ServiceRequest, DataFailure>> rebook(String jobId);
}
