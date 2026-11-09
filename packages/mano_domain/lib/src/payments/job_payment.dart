/// What the payer must do next, or that it is done.
enum JobPaymentStatus { awaitingApproval, redirect, pending, completed, failed }

/// A job's payment (gateway: `PaymentResult`); amounts in whole pesos.
final class JobPayment {
  const JobPayment({
    required this.paymentId,
    required this.jobId,
    required this.amount,
    required this.feeAmount,
    required this.status,
    this.redirectUrl,
    this.failureReason,
  });

  final String paymentId;
  final String jobId;

  /// What the payer is charged; the fee comes out of the provider's payout.
  final int amount;
  final int feeAmount;
  final JobPaymentStatus status;

  /// The bank's page, for [JobPaymentStatus.redirect].
  final String? redirectUrl;
  final String? failureReason;

  int get total => amount;
  bool get isSettled => status == JobPaymentStatus.completed;
}
