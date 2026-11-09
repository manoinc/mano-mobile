import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  const nequi = JobPaymentDraft(
    jobId: 'job-1',
    method: JobPaymentMethod.nequi,
    phone: '300 123 4567',
    payerEmail: 'ana@mano.test',
    termsAccepted: true,
  );

  test('a Nequi draft with a mobile, an email and terms is valid', () {
    expect(nequi.problems, isEmpty);
    expect(nequi.nequiPhone, '3001234567');
  });

  test('every missing piece is a problem', () {
    const empty = JobPaymentDraft(jobId: 'job-1');

    expect(empty.problems, {
      JobPaymentProblem.noMethod,
      JobPaymentProblem.invalidPayerEmail,
      JobPaymentProblem.termsNotAccepted,
    });
  });

  test('PSE needs a bank and a valid id', () {
    final pse = nequi.copyWith(method: JobPaymentMethod.pse);

    expect(pse.problems, {
      JobPaymentProblem.noBank,
      JobPaymentProblem.invalidLegalId,
    });
  });

  test('only a completed payment settles the job', () {
    JobPayment payment(JobPaymentStatus status) => JobPayment(
      paymentId: 'p',
      jobId: 'job-1',
      amount: 100000,
      feeAmount: 5000,
      status: status,
    );

    expect(payment(JobPaymentStatus.completed).isSettled, isTrue);
    expect(payment(JobPaymentStatus.pending).isSettled, isFalse);
    expect(payment(JobPaymentStatus.completed).total, 100000);
  });
}
