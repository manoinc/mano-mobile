import '../result.dart';
import '../shared/data_failure.dart';
import 'coin_pack.dart';
import 'coin_transaction.dart';
import 'pack_purchase.dart';
import 'wallet.dart';

/// The provider's coins: balance, history and top-ups. Leads spend them (see LeadRepository).
abstract interface class WalletRepository {
  Future<Wallet> wallet();

  /// Newest first.
  Future<List<CoinTransaction>> history();

  Future<List<CoinPack>> packs();

  /// What the payer must accept before buying.
  Future<List<CheckoutTerm>> checkoutTerms();

  /// Starts a purchase; the coins arrive when the charge completes.
  Future<Result<PackPurchase, DataFailure>> buyPack(
    String packId,
    NequiPayment payment,
  );
}
