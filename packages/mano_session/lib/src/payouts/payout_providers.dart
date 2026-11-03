import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

// Mock: registerPayoutAccount is a gateway stub with no billing bridge.
final payoutAccountsProvider = Provider<PayoutAccounts>(
  (ref) => MockPayoutAccounts(),
);

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
