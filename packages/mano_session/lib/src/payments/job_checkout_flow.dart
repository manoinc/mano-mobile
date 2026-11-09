import 'package:mano_domain/mano_domain.dart';

/// Where paying a job is: idle, sending, waiting on the payer, or done.
sealed class JobCheckoutFlow {
  const JobCheckoutFlow();
}

final class CheckoutIdle extends JobCheckoutFlow {
  const CheckoutIdle();
}

final class CheckoutSubmitting extends JobCheckoutFlow {
  const CheckoutSubmitting();
}

/// Billing took the payment; its status says what the payer does next.
final class CheckoutWaiting extends JobCheckoutFlow {
  const CheckoutWaiting(this.payment);

  final JobPayment payment;
}

final class CheckoutPaid extends JobCheckoutFlow {
  const CheckoutPaid(this.payment);

  final JobPayment payment;
}

/// Still not settled after the wait; it may land later.
final class CheckoutTimedOut extends JobCheckoutFlow {
  const CheckoutTimedOut(this.payment);

  final JobPayment payment;
}

final class CheckoutFailed extends JobCheckoutFlow {
  const CheckoutFailed(this.failure);

  final DataFailure failure;
}
