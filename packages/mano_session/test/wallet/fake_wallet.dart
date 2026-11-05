import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

/// A scriptable wallet: [replies] answer buyPack in order, [creditAfterReads] decides when coins land.
final class FakeWallet implements WalletRepository {
  FakeWallet({
    this.balance = 10,
    List<Result<CoinPurchase, DataFailure>>? replies,
    this.creditAfterReads,
  }) : replies = replies ?? [];

  int balance;
  final List<Result<CoinPurchase, DataFailure>> replies;

  /// Null never credits; otherwise the read that sees the coins, counted after a buy.
  final int? creditAfterReads;

  final _mock = MockWalletRepository();
  var buys = 0;
  var readsSinceBuy = 0;
  int _pendingCoins = 0;

  @override
  Future<Wallet> wallet() async {
    readsSinceBuy++;
    if (_pendingCoins > 0 && readsSinceBuy == creditAfterReads) {
      balance += _pendingCoins;
      _pendingCoins = 0;
    }
    return Wallet(balance: balance);
  }

  @override
  Future<Result<CoinPurchase, DataFailure>> buyPack(
    CoinPurchaseDraft draft,
  ) async {
    final reply = replies.length > 1 ? replies.removeAt(0) : replies.first;
    buys++;
    readsSinceBuy = 0;
    if (reply case Ok(:final value) when !value.isSettled) {
      _pendingCoins = value.coins;
    }
    if (reply case Ok(value: PurchaseCompleted(:final coins))) {
      balance += coins;
    }
    return reply;
  }

  @override
  Future<List<CoinTransaction>> history() async => const [];

  @override
  Future<List<CoinPack>> packs() => _mock.packs();

  @override
  Future<Result<List<CheckoutTerm>, DataFailure>> checkoutTerms() =>
      _mock.checkoutTerms();

  @override
  Future<Result<List<Bank>, DataFailure>> pseBanks() => _mock.pseBanks();

  @override
  Future<Result<CoinTransaction, DataFailure>> spendForLead(
    String requestId,
    int cost, {
    required String label,
  }) => _mock.spendForLead(requestId, cost, label: label);

  @override
  Future<Result<Wallet, DataFailure>> refundLead(String requestId) =>
      _mock.refundLead(requestId);
}
