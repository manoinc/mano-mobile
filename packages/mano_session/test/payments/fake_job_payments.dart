import 'package:mano_domain/mano_domain.dart';

/// Scriptable job payments: [payReplies] answer pay, [reads] answer payment in order (the last repeats).
final class FakeJobPayments implements JobPaymentRepository {
  FakeJobPayments({
    required this.payReplies,
    List<Result<JobPayment?, DataFailure>>? reads,
  }) : reads = reads ?? [const Ok(null)];

  final List<Result<JobPayment, DataFailure>> payReplies;
  final List<Result<JobPayment?, DataFailure>> reads;
  var pays = 0;
  var readCount = 0;

  @override
  Future<Result<JobPayment, DataFailure>> pay(JobPaymentDraft draft) async {
    pays++;
    return payReplies.length > 1 ? payReplies.removeAt(0) : payReplies.first;
  }

  @override
  Future<Result<JobPayment?, DataFailure>> payment(String jobId) async {
    readCount++;
    return reads.length > 1 ? reads.removeAt(0) : reads.first;
  }

  @override
  Future<Result<List<CheckoutTerm>, DataFailure>> checkoutTerms() async =>
      const Ok([]);

  @override
  Future<Result<List<Bank>, DataFailure>> pseBanks() async => const Ok([]);
}

JobPayment jobPayment(JobPaymentStatus status, {String? url, String? reason}) =>
    JobPayment(
      paymentId: 'pay-1',
      jobId: 'job-1',
      amount: 120000,
      feeAmount: 6000,
      status: status,
      redirectUrl: url,
      failureReason: reason,
    );
