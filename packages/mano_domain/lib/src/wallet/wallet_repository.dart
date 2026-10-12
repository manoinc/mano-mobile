import '../result.dart';
import '../shared/data_failure.dart';
import 'coin_pack.dart';
import 'coin_transaction.dart';
import 'wallet.dart';

/// The provider's coins: balance, history, top-ups and lead payments.
abstract interface class WalletRepository {
  Future<Wallet> wallet();

  /// Newest first.
  Future<List<CoinTransaction>> history();

  Future<List<CoinPack>> packs();

  Future<Result<Wallet, DataFailure>> buyPack(String packId);

  /// Pays [cost] coins to answer [requestId]; [InsufficientCoins] when short.
  Future<Result<CoinTransaction, DataFailure>> spendForLead(
    String requestId,
    int cost, {
    required String label,
  });

  /// Gives back what [requestId] cost, e.g. when the answer itself failed.
  Future<Result<Wallet, DataFailure>> refundLead(String requestId);
}
