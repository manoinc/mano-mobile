import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../marketplace_providers.dart';

// Shared by both apps: the requester's Actividad tab and the provider's agenda and requests.

final jobProvider = FutureProvider.family<Job?, String>(
  (ref, id) => ref.watch(jobRepositoryProvider).job(id),
);

final jobsByStatusProvider = FutureProvider.family<List<Job>, JobStatus>((
  ref,
  status,
) async {
  final jobs = await ref.watch(myJobsProvider.future);
  return [
    for (final job in jobs)
      if (job.status == status) job,
  ];
});

final requestsByStatusProvider =
    FutureProvider.family<List<ServiceRequest>, ServiceRequestStatus>((
      ref,
      status,
    ) async {
      final requests = await ref.watch(myServiceRequestsProvider.future);
      return [
        for (final request in requests)
          if (request.status == status) request,
      ];
    });

/// Job and request mutations; each success invalidates the reads it changed.
final class ActivityActions extends Notifier<void> {
  @override
  void build() {}

  Future<Result<Job, DataFailure>> cancelJob(
    String id, {
    String? reason,
  }) async {
    final result = await ref
        .read(jobRepositoryProvider)
        .cancel(id, reason: reason);
    if (result.isOk) _refreshJobs();
    return result;
  }

  Future<Result<ServiceRequest, DataFailure>> rebook(String jobId) async {
    final result = await ref.read(jobRepositoryProvider).rebook(jobId);
    if (result.isOk) ref.invalidate(myServiceRequestsProvider);
    return result;
  }

  Future<Result<ServiceRequest, DataFailure>> cancelRequest(String id) async {
    final result = await ref.read(serviceRequestRepositoryProvider).cancel(id);
    if (result.isOk) ref.invalidate(myServiceRequestsProvider);
    return result;
  }

  void _refreshJobs() {
    ref
      ..invalidate(myJobsProvider)
      ..invalidate(jobProvider);
  }
}

final activityActionsProvider = NotifierProvider<ActivityActions, void>(
  ActivityActions.new,
);
