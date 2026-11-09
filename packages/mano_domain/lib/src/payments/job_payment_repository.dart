import '../result.dart';
import '../shared/bank.dart';
import '../shared/data_failure.dart';
import '../wallet/checkout_term.dart';
import 'job_payment.dart';
import 'job_payment_draft.dart';

/// Paying a finished job (gateway: `payJob`, `jobPayment`).
abstract interface class JobPaymentRepository {
  /// Idempotent per job: a retry returns the live payment.
  Future<Result<JobPayment, DataFailure>> pay(JobPaymentDraft draft);

  /// `Ok(null)` when the job has not been paid.
  Future<Result<JobPayment?, DataFailure>> payment(String jobId);

  Future<Result<List<CheckoutTerm>, DataFailure>> checkoutTerms();

  Future<Result<List<Bank>, DataFailure>> pseBanks();
}
