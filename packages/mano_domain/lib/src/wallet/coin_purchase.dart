/// Where a coin pack purchase stands; coins land only once it is completed.
sealed class CoinPurchase {
  const CoinPurchase({required this.paymentId, required this.coins});

  final String paymentId;

  /// Pack plus bonus, credited on completion.
  final int coins;

  bool get isSettled => this is PurchaseCompleted;
}

/// Nequi sent a push: the payer approves it in the Nequi app.
final class AwaitingApproval extends CoinPurchase {
  const AwaitingApproval({required super.paymentId, required super.coins});
}

/// PSE: the payer finishes on the bank's page at [url].
final class BankRedirect extends CoinPurchase {
  const BankRedirect({
    required super.paymentId,
    required super.coins,
    required this.url,
  });

  final String url;
}

/// Nothing to do yet, e.g. the bank's page is not ready: ask again.
final class PurchasePending extends CoinPurchase {
  const PurchasePending({required super.paymentId, required super.coins});
}

/// The charge went through and the coins are in the wallet.
final class PurchaseCompleted extends CoinPurchase {
  const PurchaseCompleted({required super.paymentId, required super.coins});
}
