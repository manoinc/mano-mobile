enum CoinTransactionKind { purchase, leadSpend, referralBonus, refund }

/// One line of the coin history; [amount] is positive for credits, negative for spends.
final class CoinTransaction {
  const CoinTransaction({
    required this.id,
    required this.kind,
    required this.amount,
    required this.label,
    required this.at,
    this.requestId,
  });

  final String id;
  final CoinTransactionKind kind;
  final int amount;
  final String label;
  final DateTime at;
  final String? requestId;

  bool get isCredit => amount > 0;

  @override
  bool operator ==(Object other) =>
      other is CoinTransaction &&
      other.id == id &&
      other.kind == kind &&
      other.amount == amount &&
      other.label == label &&
      other.at == at &&
      other.requestId == requestId;

  @override
  int get hashCode => Object.hash(id, kind, amount, label, at, requestId);

  @override
  String toString() => 'CoinTransaction($id, $kind, $amount)';
}
