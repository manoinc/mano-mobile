import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../marketplace_providers.dart';

/// The provider's answers to incoming requests; each success refreshes requests and jobs.
final class RequestActions extends Notifier<void> {
  @override
  void build() {}

  Future<Result<ServiceRequest, DataFailure>> accept(String id) =>
      _refreshOnOk(ref.read(serviceRequestRepositoryProvider).accept(id));

  Future<Result<ServiceRequest, DataFailure>> reject(
    String id, {
    String? reason,
  }) => _refreshOnOk(
    ref.read(serviceRequestRepositoryProvider).reject(id, reason: reason),
  );

  Future<Result<ServiceRequest, DataFailure>> _refreshOnOk(
    Future<Result<ServiceRequest, DataFailure>> action,
  ) async {
    final result = await action;
    // Accepting schedules a job, so the agenda must refetch too.
    if (result.isOk) {
      ref
        ..invalidate(myServiceRequestsProvider)
        ..invalidate(myJobsProvider);
    }
    return result;
  }
}

final requestActionsProvider = NotifierProvider<RequestActions, void>(
  RequestActions.new,
);
