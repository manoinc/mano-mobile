import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../marketplace_providers.dart';
import '../wallet/wallet_providers.dart';

/// The provider's answers to incoming requests; each success refreshes requests and jobs.
final class RequestActions extends Notifier<void> {
  @override
  void build() {}

  Future<Result<ServiceRequest, DataFailure>> accept(String id) =>
      _refreshOnOk(ref.read(serviceRequestRepositoryProvider).accept(id));

  /// Pays the lead's cost in coins, then accepts; gives the coins back if the accept fails.
  Future<Result<ServiceRequest, DataFailure>> respond(
    ServiceRequest request,
  ) async {
    final wallet = ref.read(walletRepositoryProvider);
    final paid = await wallet.spendForLead(
      request.id,
      request.leadCost,
      label: 'Solicitud de ${ServiceCategories.labelOf(request.category)}',
    );
    if (paid case Err(:final failure)) return Err(failure);
    final result = await _refreshOnOk(
      ref.read(serviceRequestRepositoryProvider).accept(request.id),
    );
    if (result.isErr) await wallet.refundLead(request.id);
    refreshWallet(ref);
    return result;
  }

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
