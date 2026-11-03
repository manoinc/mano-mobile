/// A pack paid with Nequi: the payer approves the charge in the Nequi app.
final class NequiPayment {
  const NequiPayment({
    required this.phone,
    required this.payerEmail,
    required this.acceptedTerms,
  });

  final String phone;
  final String payerEmail;
  final bool acceptedTerms;
}

/// What the payer does next once a purchase is started.
enum PurchaseStep { approveInNequi, openBank, wait, done }

/// A started pack purchase; its coins arrive once the charge completes.
final class PackPurchase {
  const PackPurchase({
    required this.paymentId,
    required this.coins,
    required this.step,
    this.redirectUrl,
  });

  final String paymentId;
  final int coins;
  final PurchaseStep step;
  final String? redirectUrl;

  @override
  bool operator ==(Object other) =>
      other is PackPurchase &&
      other.paymentId == paymentId &&
      other.coins == coins &&
      other.step == step &&
      other.redirectUrl == redirectUrl;

  @override
  int get hashCode => Object.hash(paymentId, coins, step, redirectUrl);

  @override
  String toString() => 'PackPurchase($paymentId, $coins, $step)';
}

/// A document the payer accepts before paying, from the payment gateway.
final class CheckoutTerm {
  const CheckoutTerm({required this.label, required this.url});

  final String label;
  final String url;

  @override
  bool operator ==(Object other) =>
      other is CheckoutTerm && other.label == label && other.url == url;

  @override
  int get hashCode => Object.hash(label, url);
}
