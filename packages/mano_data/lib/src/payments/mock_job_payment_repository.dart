import 'package:mano_domain/mano_domain.dart';

import '../mock/mock_banks.dart';

/// In-memory job payments; a started payment completes on the next read.
final class MockJobPaymentRepository implements JobPaymentRepository {
  MockJobPaymentRepository({this.amount = 120000, this.feeBps = 500});

  final int amount;
  final int feeBps;
  final Map<String, JobPayment> _payments = {};

  static const _terms = [
    CheckoutTerm(
      label: 'Términos y condiciones de la pasarela',
      url: 'https://mano.test/terminos',
    ),
  ];

  @override
  Future<Result<JobPayment, DataFailure>> pay(JobPaymentDraft draft) async {
    if (!draft.isValid) {
      return Err(DataRejected(reason: draft.problems.join(',')));
    }
    final existing = _payments[draft.jobId];
    if (existing != null) return Ok(existing);
    final pse = draft.method == JobPaymentMethod.pse;
    return Ok(
      _payments[draft.jobId] = _payment(
        draft.jobId,
        pse ? JobPaymentStatus.redirect : JobPaymentStatus.awaitingApproval,
        redirectUrl: pse ? 'https://mano.test/pse/${draft.jobId}' : null,
      ),
    );
  }

  @override
  Future<Result<JobPayment?, DataFailure>> payment(String jobId) async {
    final started = _payments[jobId];
    if (started == null) return const Ok(null);
    return Ok(_payments[jobId] = _payment(jobId, JobPaymentStatus.completed));
  }

  @override
  Future<Result<List<CheckoutTerm>, DataFailure>> checkoutTerms() async =>
      const Ok(_terms);

  @override
  Future<Result<List<Bank>, DataFailure>> pseBanks() async =>
      const Ok(mockBanks);

  JobPayment _payment(
    String jobId,
    JobPaymentStatus status, {
    String? redirectUrl,
  }) => JobPayment(
    paymentId: 'pay-$jobId',
    jobId: jobId,
    amount: amount,
    feeAmount: amount * feeBps ~/ 10000,
    status: status,
    redirectUrl: redirectUrl,
  );
}
