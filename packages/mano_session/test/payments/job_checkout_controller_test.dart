import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

import 'fake_job_payments.dart';

const _draft = JobPaymentDraft(
  jobId: 'job-1',
  method: JobPaymentMethod.nequi,
  phone: '3001234567',
  payerEmail: 'ana@mano.test',
  termsAccepted: true,
);

// Backoff waits 1, 2, 4, 4… seconds; the wait gives up after 10.
const _config = BillingConfig(
  pollInterval: Duration(seconds: 1),
  settleTimeout: Duration(seconds: 10),
);

final _awaiting = Ok<JobPayment, DataFailure>(
  jobPayment(JobPaymentStatus.awaitingApproval),
);

ProviderContainer _container(FakeJobPayments payments) {
  final c = ProviderContainer.test(
    overrides: [
      jobPaymentRepositoryProvider.overrideWithValue(payments),
      billingConfigProvider.overrideWithValue(_config),
    ],
  );
  // Keeps the auto-disposed controller alive, as the checkout screen does.
  c.listen(jobCheckoutProvider, (_, _) {});
  return c;
}

JobCheckoutFlow _flow(ProviderContainer c) => c.read(jobCheckoutProvider);

JobCheckoutController _controller(ProviderContainer c) =>
    c.read(jobCheckoutProvider.notifier);

void main() {
  test('backoff doubles from the poll interval, up to four times it', () {
    expect(
      [for (var i = 0; i < 5; i++) _config.backoff(i).inSeconds],
      [1, 2, 4, 4, 4],
    );
  });

  test('awaits Nequi, polls jobPayment with backoff, then is paid', () {
    fakeAsync((async) {
      final payments = FakeJobPayments(
        payReplies: [_awaiting],
        reads: [_awaiting, Ok(jobPayment(JobPaymentStatus.completed))],
      );
      final c = _container(payments);
      _controller(c).pay(_draft);
      async.flushMicrotasks();
      expect(
        (_flow(c) as CheckoutWaiting).payment.status,
        JobPaymentStatus.awaitingApproval,
      );

      async.elapse(const Duration(seconds: 1));
      expect(payments.readCount, 1);
      expect(_flow(c), isA<CheckoutWaiting>());

      async.elapse(const Duration(seconds: 1));
      expect(payments.readCount, 1, reason: 'the second wait is longer');

      async.elapse(const Duration(seconds: 1));
      expect(payments.readCount, 2);
      expect((_flow(c) as CheckoutPaid).payment.amount, 120000);
    });
  });

  test('PSE redirects; a pending payment waits for the bank link', () {
    fakeAsync((async) {
      final payments = FakeJobPayments(
        payReplies: [Ok(jobPayment(JobPaymentStatus.pending))],
        reads: [
          Ok(jobPayment(JobPaymentStatus.redirect, url: 'https://bank.test')),
        ],
      );
      final c = _container(payments);
      _controller(c).pay(_draft);
      async.flushMicrotasks();
      expect(
        (_flow(c) as CheckoutWaiting).payment.status,
        JobPaymentStatus.pending,
      );

      async.elapse(const Duration(seconds: 1));
      expect(
        (_flow(c) as CheckoutWaiting).payment.redirectUrl,
        'https://bank.test',
      );
    });
  });

  test('gives up after the timeout; checking again can land', () {
    fakeAsync((async) {
      final payments = FakeJobPayments(
        payReplies: [_awaiting],
        reads: [_awaiting],
      );
      final c = _container(payments);
      _controller(c).pay(_draft);
      async.elapse(const Duration(seconds: 12));
      expect(_flow(c), isA<CheckoutTimedOut>());
      final reads = payments.readCount;
      async.elapse(const Duration(seconds: 30));
      expect(payments.readCount, reads, reason: 'polling stopped');

      payments.reads
        ..clear()
        ..add(Ok(jobPayment(JobPaymentStatus.completed)));
      _controller(c).checkNow();
      async.flushMicrotasks();
      expect(_flow(c), isA<CheckoutPaid>());
    });
  });

  test('a missed read keeps waiting', () {
    fakeAsync((async) {
      final payments = FakeJobPayments(
        payReplies: [_awaiting],
        reads: [
          const Err(DataUnavailable(detail: 'down')),
          Ok(jobPayment(JobPaymentStatus.completed)),
        ],
      );
      final c = _container(payments);
      _controller(c).pay(_draft);
      async.elapse(const Duration(seconds: 1));
      expect(_flow(c), isA<CheckoutWaiting>());
      async.elapse(const Duration(seconds: 2));
      expect(_flow(c), isA<CheckoutPaid>());
    });
  });

  test('a completed reply is paid at once', () {
    fakeAsync((async) {
      final c = _container(
        FakeJobPayments(
          payReplies: [Ok(jobPayment(JobPaymentStatus.completed))],
        ),
      );
      _controller(c).pay(_draft);
      async.flushMicrotasks();
      expect(_flow(c), isA<CheckoutPaid>());
    });
  });

  test('a failed payment carries its reason, and reset starts over', () {
    fakeAsync((async) {
      final c = _container(
        FakeJobPayments(
          payReplies: [_awaiting],
          reads: [Ok(jobPayment(JobPaymentStatus.failed, reason: 'declined'))],
        ),
      );
      _controller(c).pay(_draft);
      async.elapse(const Duration(seconds: 1));
      final failure = (_flow(c) as CheckoutFailed).failure;
      expect(failure, isA<DataRejected>());
      expect((failure as DataRejected).reason, 'declined');

      _controller(c).reset();
      expect(_flow(c), isA<CheckoutIdle>());
    });
  });

  test('a refusal is a failure', () {
    fakeAsync((async) {
      final c = _container(
        FakeJobPayments(
          payReplies: [const Err(DataRejected(reason: 'not payable'))],
        ),
      );
      _controller(c).pay(_draft);
      async.flushMicrotasks();
      expect(_flow(c), isA<CheckoutFailed>());
    });
  });

  test('an invalid draft is refused without calling billing', () {
    fakeAsync((async) {
      final payments = FakeJobPayments(payReplies: [_awaiting]);
      final c = _container(payments);
      _controller(c).pay(_draft.copyWith(termsAccepted: false));
      async.flushMicrotasks();
      expect(_flow(c), isA<CheckoutFailed>());
      expect(payments.pays, 0);
    });
  });

  test('once paid, the job reads as paid again', () {
    fakeAsync((async) {
      final payments = FakeJobPayments(
        payReplies: [Ok(jobPayment(JobPaymentStatus.completed))],
        reads: [const Ok(null)],
      );
      final c = _container(payments);
      c.listen(jobPaymentProvider('job-1'), (_, _) {});
      async.flushMicrotasks();
      expect(c.read(jobPaymentProvider('job-1')).value, isNull);

      payments.reads[0] = Ok(jobPayment(JobPaymentStatus.completed));
      _controller(c).pay(_draft);
      async.elapse(const Duration(milliseconds: 1));
      expect(c.read(jobPaymentProvider('job-1')).value?.isSettled, isTrue);
    });
  });
}
