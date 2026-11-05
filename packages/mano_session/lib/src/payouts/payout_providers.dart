import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../offline_marketplace_provider.dart';
import '../session_providers.dart';

// Live on D6; the gateway cannot read the account back, so only this session's registration shows.
final payoutAccountsProvider = Provider<PayoutAccounts>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? MockPayoutAccounts()
      : GatewayPayoutAccounts(ref.watch(gatewayTransportProvider)),
);

/// The banks a payout can go to; a failure is an error state.
final payoutBanksProvider = FutureProvider<List<Bank>>((ref) async {
  final result = await ref.watch(payoutAccountsProvider).banks();
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// The registered payout account, or null; a read failure is an error state.
final payoutAccountProvider = FutureProvider<PayoutAccount?>((ref) async {
  final result = await ref.watch(payoutAccountsProvider).current();
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// Registering and removing the payout account.
final class PayoutActions extends Notifier<void> {
  @override
  void build() {}

  PayoutAccounts get _accounts => ref.read(payoutAccountsProvider);

  Future<Result<PayoutAccount, DataFailure>> register(
    PayoutAccountDraft draft,
  ) async {
    if (!draft.isValid) return Err(DataRejected(reason: '${draft.problems}'));
    final result = await _accounts.register(
      destination: draft.destination,
      holder: draft.holder,
    );
    if (result.isOk) ref.invalidate(payoutAccountProvider);
    return result;
  }

  Future<Result<void, DataFailure>> remove(String accountId) async {
    final result = await _accounts.remove(accountId);
    if (result.isOk) ref.invalidate(payoutAccountProvider);
    return result;
  }
}

final payoutActionsProvider = NotifierProvider<PayoutActions, void>(
  PayoutActions.new,
);
