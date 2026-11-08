import 'package:mano_domain/mano_domain.dart';

import '../billing/billing_json.dart';
import '../mock/mock_banks.dart';

/// In-memory [WalletRepository]; a purchase stays pending until the next balance read, like a webhook landing.
final class MockWalletRepository implements WalletRepository {
  MockWalletRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now {
    final today = _now();
    CoinTransaction tx(
      String id,
      CoinTransactionKind kind,
      int amount,
      String label,
      int daysAgo,
    ) => CoinTransaction(
      id: id,
      kind: kind,
      amount: amount,
      label: label,
      at: today.subtract(Duration(days: daysAgo)),
    );
    _history.addAll([
      tx('tx-7', CoinTransactionKind.refund, 2, 'Reembolso de contacto', 2),
      tx('tx-6', CoinTransactionKind.leadSpend, -3, leadSpendLabel, 3),
      tx('tx-5', CoinTransactionKind.leadSpend, -4, leadSpendLabel, 6),
      tx(
        'tx-4',
        CoinTransactionKind.referralBonus,
        5,
        'Bono por referir a Carlos',
        9,
      ),
      tx('tx-3', CoinTransactionKind.leadSpend, -2, leadSpendLabel, 12),
      tx('tx-2', CoinTransactionKind.leadSpend, -3, leadSpendLabel, 15),
      tx('tx-1', CoinTransactionKind.purchase, 30, purchaseLabel(30), 20),
    ]);
    _balance = _history.fold(0, (sum, t) => sum + t.amount);
  }

  static const _packs = [
    CoinPack(id: 'pack-20', coins: 20, priceCop: 20000),
    CoinPack(id: 'pack-50', coins: 50, priceCop: 50000, bonus: 5),
    CoinPack(id: 'pack-100', coins: 100, priceCop: 100000, bonus: 20),
  ];

  static const _terms = [
    CheckoutTerm(
      label: 'Términos y condiciones de la pasarela',
      url: 'https://mano.test/terminos',
    ),
  ];

  final DateTime Function() _now;
  final List<CoinTransaction> _history = [];
  final List<CoinPack> _pending = [];
  late int _balance;
  int _nextId = 100;

  void _record(CoinTransactionKind kind, int amount, String label) {
    _balance += amount;
    _history.insert(
      0,
      CoinTransaction(
        id: 'tx-${_nextId++}',
        kind: kind,
        amount: amount,
        label: label,
        at: _now(),
      ),
    );
  }

  @override
  Future<Wallet> wallet() async {
    for (final pack in _pending) {
      _record(
        CoinTransactionKind.purchase,
        pack.totalCoins,
        purchaseLabel(pack.totalCoins),
      );
    }
    _pending.clear();
    return Wallet(balance: _balance);
  }

  @override
  Future<List<CoinTransaction>> history() async => List.of(_history);

  @override
  Future<List<CoinPack>> packs() async => _packs;

  @override
  Future<Result<CoinPurchase, DataFailure>> buyPack(
    CoinPurchaseDraft draft,
  ) async {
    if (!draft.isValid) {
      return Err(DataRejected(reason: 'invalid draft: ${draft.problems}'));
    }
    final pack = _packs.where((p) => p.id == draft.packId).firstOrNull;
    if (pack == null) return const Err(DataNotFound());
    _pending.add(pack);
    final id = 'payment-${_nextId++}';
    return Ok(switch (draft.method) {
      CoinPurchaseMethod.pse => BankRedirect(
        paymentId: id,
        coins: pack.totalCoins,
        url: 'https://pse.mano.test/$id',
      ),
      _ => AwaitingApproval(paymentId: id, coins: pack.totalCoins),
    });
  }

  @override
  Future<Result<List<CheckoutTerm>, DataFailure>> checkoutTerms() async =>
      const Ok(_terms);

  @override
  Future<Result<List<Bank>, DataFailure>> pseBanks() async =>
      const Ok(mockBanks);

  @override
  Future<LeadPricing> leadPrices() async => LeadPricing.launch;

  /// Offline lead purchases pay here; [InsufficientCoins] when short.
  Result<Wallet, DataFailure> spendOnLead(int coins) {
    if (coins > _balance) return const Err(InsufficientCoins());
    _record(CoinTransactionKind.leadSpend, -coins, leadSpendLabel);
    return Ok(Wallet(balance: _balance));
  }
}
