import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

void main() {
  const nequi = JobPaymentDraft(
    jobId: 'job-1',
    method: JobPaymentMethod.nequi,
    phone: '3001234567',
    payerEmail: 'ana@mano.test',
    termsAccepted: true,
  );

  test('an unpaid job has no payment', () async {
    final repo = MockJobPaymentRepository();

    expect((await repo.payment('job-1')).valueOrNull, isNull);
  });

  test('Nequi waits for approval, then the next read is completed', () async {
    final repo = MockJobPaymentRepository();

    final started = (await repo.pay(nequi)).valueOrNull!;
    final later = (await repo.payment('job-1')).valueOrNull!;

    expect(started.status, JobPaymentStatus.awaitingApproval);
    expect(later.isSettled, isTrue);
  });

  test('PSE sends the payer to the bank', () async {
    final repo = MockJobPaymentRepository();
    final pse = nequi.copyWith(
      method: JobPaymentMethod.pse,
      bankCode: '1007',
      legalId: '1020304050',
    );

    final started = (await repo.pay(pse)).valueOrNull!;

    expect(started.status, JobPaymentStatus.redirect);
    expect(started.redirectUrl, isNotNull);
  });

  test('an invalid draft is rejected without charging', () async {
    final repo = MockJobPaymentRepository();

    final result = await repo.pay(const JobPaymentDraft(jobId: 'job-1'));

    expect(result.failureOrNull, isA<DataRejected>());
    expect((await repo.payment('job-1')).valueOrNull, isNull);
  });
}
