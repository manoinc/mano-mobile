import 'package:mano_domain/mano_domain.dart';

/// Where the Recargar sheet is: idle, sending, waiting on the payer, or done.
sealed class CoinPurchaseFlow {
  const CoinPurchaseFlow();
}

final class PurchaseIdle extends CoinPurchaseFlow {
  const PurchaseIdle();
}

final class PurchaseSubmitting extends CoinPurchaseFlow {
  const PurchaseSubmitting();
}

/// Billing took the purchase; [step] says what the payer does next.
final class PurchaseWaiting extends CoinPurchaseFlow {
  const PurchaseWaiting(this.step);

  final CoinPurchase step;
}

/// The coins are in: the balance moved by [coins] to [balance].
final class PurchaseCredited extends CoinPurchaseFlow {
  const PurchaseCredited({required this.coins, required this.balance});

  final int coins;
  final int balance;
}

/// Still not settled after the wait; it may land later.
final class PurchaseTimedOut extends CoinPurchaseFlow {
  const PurchaseTimedOut(this.step);

  final CoinPurchase step;
}

final class PurchaseFailed extends CoinPurchaseFlow {
  const PurchaseFailed(this.failure);

  final DataFailure failure;
}
