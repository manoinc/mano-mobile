import 'package:mano_domain/mano_domain.dart';

/// In-memory [WalletRepository] with a believable history and three packs.
final class MockWalletRepository implements WalletRepository {
  MockWalletRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now {
    final today = _now();
    CoinTransaction tx(
      String id,
      CoinTransactionKind kind,
      int amount,
      String label,
      int daysAgo, {
      String? requestId,
    }) => CoinTransaction(
      id: id,
      kind: kind,
      amount: amount,
      label: label,
      at: today.subtract(Duration(days: daysAgo)),
      requestId: requestId,
    );
    _history.addAll([
      tx(
        'tx-7',
        CoinTransactionKind.refund,
        2,
        'Reembolso · Limpieza',
        2,
        requestId: 'request-4',
      ),
      tx(
        'tx-6',
        CoinTransactionKind.leadSpend,
        -3,
        'Solicitud de Plomería',
        3,
        requestId: 'request-3',
      ),
      tx(
        'tx-5',
        CoinTransactionKind.leadSpend,
        -4,
        'Solicitud de Pintura',
        6,
        requestId: 'request-0',
      ),
      tx(
        'tx-4',
        CoinTransactionKind.referralBonus,
        5,
        'Bono por referir a Carlos',
        9,
      ),
      tx(
        'tx-3',
        CoinTransactionKind.leadSpend,
        -2,
        'Solicitud de Limpieza',
        12,
        requestId: 'request-4',
      ),
      tx(
        'tx-2',
        CoinTransactionKind.leadSpend,
        -3,
        'Solicitud de Electricidad',
        15,
        requestId: 'request-00',
      ),
      tx('tx-1', CoinTransactionKind.purchase, 30, 'Recarga de 30 coins', 20),
    ]);
    _balance = _history.fold(0, (sum, t) => sum + t.amount);
  }

  static const _packs = [
    CoinPack(id: 'pack-10', coins: 10, priceCop: 20000),
    CoinPack(id: 'pack-25', coins: 25, priceCop: 45000, bonus: 3),
    CoinPack(id: 'pack-60', coins: 60, priceCop: 100000, bonus: 10),
  ];

  final DateTime Function() _now;
  final List<CoinTransaction> _history = [];
  late int _balance;
  int _nextId = 100;

  void _record(
    CoinTransactionKind kind,
    int amount,
    String label, {
    String? requestId,
  }) {
    _balance += amount;
    _history.insert(
      0,
      CoinTransaction(
        id: 'tx-${_nextId++}',
        kind: kind,
        amount: amount,
        label: label,
        at: _now(),
        requestId: requestId,
      ),
    );
  }

  @override
  Future<Wallet> wallet() async => Wallet(balance: _balance);

  @override
  Future<List<CoinTransaction>> history() async => List.of(_history);

  @override
  Future<List<CoinPack>> packs() async => _packs;

  @override
  Future<Result<Wallet, DataFailure>> buyPack(String packId) async {
    final pack = _packs.where((p) => p.id == packId).firstOrNull;
    if (pack == null) return const Err(DataNotFound());
    _record(
      CoinTransactionKind.purchase,
      pack.totalCoins,
      'Recarga de ${pack.totalCoins} coins',
    );
    return Ok(Wallet(balance: _balance));
  }

  @override
  Future<Result<CoinTransaction, DataFailure>> spendForLead(
    String requestId,
    int cost, {
    required String label,
  }) async {
    if (cost > _balance) {
      return Err(InsufficientCoins(needed: cost, available: _balance));
    }
    _record(CoinTransactionKind.leadSpend, -cost, label, requestId: requestId);
    return Ok(_history.first);
  }

  @override
  Future<Result<Wallet, DataFailure>> refundLead(String requestId) async {
    bool isFor(CoinTransaction t, CoinTransactionKind kind) =>
        t.requestId == requestId && t.kind == kind;
    final spend = _history
        .where((t) => isFor(t, CoinTransactionKind.leadSpend))
        .firstOrNull;
    final refunded = _history.any((t) => isFor(t, CoinTransactionKind.refund));
    if (spend == null || refunded) return const Err(DataNotFound());
    _record(
      CoinTransactionKind.refund,
      -spend.amount,
      'Reembolso · ${spend.label}',
      requestId: requestId,
    );
    return Ok(Wallet(balance: _balance));
  }
}
