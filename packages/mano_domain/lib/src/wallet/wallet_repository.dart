import '../result.dart';
import '../shared/bank.dart';
import '../shared/data_failure.dart';
import 'checkout_term.dart';
import 'coin_pack.dart';
import 'coin_purchase.dart';
import 'coin_purchase_draft.dart';
import 'coin_transaction.dart';
import 'wallet.dart';

/// The provider's coins: balance, history, top-ups and lead payments.
abstract interface class WalletRepository {
  Future<Wallet> wallet();

  /// Newest first.
  Future<List<CoinTransaction>> history();

  /// Cheapest first.
  Future<List<CoinPack>> packs();

  /// Starts paying for a pack; the coins land only once it completes.
  Future<Result<CoinPurchase, DataFailure>> buyPack(CoinPurchaseDraft draft);

  /// What the payer must accept before [buyPack].
  Future<Result<List<CheckoutTerm>, DataFailure>> checkoutTerms();

  /// The banks PSE can charge.
  Future<Result<List<Bank>, DataFailure>> pseBanks();

  /// Pays [cost] coins to answer [requestId]; [InsufficientCoins] when short.
  Future<Result<CoinTransaction, DataFailure>> spendForLead(
    String requestId,
    int cost, {
    required String label,
  });

  /// Gives back what [requestId] cost, e.g. when the answer itself failed.
  Future<Result<Wallet, DataFailure>> refundLead(String requestId);
}
