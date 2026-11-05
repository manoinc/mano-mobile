import '../result.dart';
import '../shared/bank.dart';
import '../shared/data_failure.dart';
import 'payout_account.dart';

/// The provider's payout account: at most one, replaced on register.
abstract interface class PayoutAccounts {
  /// Null while none is registered.
  Future<Result<PayoutAccount?, DataFailure>> current();

  Future<Result<PayoutAccount, DataFailure>> register({
    required PayoutDestination destination,
    required AccountHolder holder,
  });

  Future<Result<void, DataFailure>> remove(String accountId);

  /// The banks a payout can go to, by name.
  Future<Result<List<Bank>, DataFailure>> banks();
}
