import 'package:mano_domain/mano_domain.dart';

import '../mock/mock_banks.dart';

/// In-memory [PayoutAccounts]: one account at most, nothing is paid out.
final class MockPayoutAccounts implements PayoutAccounts {
  PayoutAccount? _current;
  var _nextId = 1;

  @override
  Future<Result<PayoutAccount?, DataFailure>> current() async => Ok(_current);

  @override
  Future<Result<PayoutAccount, DataFailure>> register({
    required PayoutDestination destination,
    required AccountHolder holder,
  }) async {
    final account = PayoutAccount(
      id: 'payout-${_nextId++}',
      destination: destination,
      holder: holder,
    );
    _current = account;
    return Ok(account);
  }

  @override
  Future<Result<void, DataFailure>> remove(String accountId) async {
    if (_current?.id != accountId) return const Err(DataNotFound());
    _current = null;
    return const Ok(null);
  }

  @override
  Future<Result<List<Bank>, DataFailure>> banks() async => const Ok(mockBanks);
}
