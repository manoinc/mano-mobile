import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../wallet/billing_config.dart';
import 'job_checkout_flow.dart';
import 'job_payment_providers.dart';

/// Pays a finished job, then polls `jobPayment` with backoff until it settles or the wait runs out.
final class JobCheckoutController extends Notifier<JobCheckoutFlow> {
  Timer? _timer;
  var _attempt = 0;
  var _waited = Duration.zero;
  var _busy = false;

  @override
  JobCheckoutFlow build() {
    ref.onDispose(_stop);
    return const CheckoutIdle();
  }

  JobPaymentRepository get _payments => ref.read(jobPaymentRepositoryProvider);
  BillingConfig get _config => ref.read(billingConfigProvider);

  Future<void> pay(JobPaymentDraft draft) async {
    _stop();
    if (!draft.isValid) {
      state = CheckoutFailed(DataRejected(reason: '${draft.problems}'));
      return;
    }
    state = const CheckoutSubmitting();
    switch (await _payments.pay(draft)) {
      case Ok(:final value):
        _apply(value);
      case Err(:final failure):
        state = CheckoutFailed(failure);
    }
  }

  /// Looks now, e.g. on app resume; also revives a timed-out wait.
  Future<void> checkNow() async {
    final payment = switch (state) {
      CheckoutWaiting(:final payment) ||
      CheckoutTimedOut(:final payment) => payment,
      _ => null,
    };
    if (payment == null) return;
    if (state is CheckoutTimedOut) _stop();
    await _look(payment.jobId);
  }

  void reset() {
    _stop();
    state = const CheckoutIdle();
  }

  void _apply(JobPayment payment) {
    switch (payment.status) {
      case JobPaymentStatus.completed:
        _stop();
        state = CheckoutPaid(payment);
        ref.invalidate(jobPaymentProvider(payment.jobId));
      case JobPaymentStatus.failed:
        _stop();
        state = CheckoutFailed(DataRejected(reason: payment.failureReason));
      case _:
        state = CheckoutWaiting(payment);
        _schedule(payment.jobId);
    }
  }

  void _schedule(String jobId) {
    if (_timer?.isActive ?? false) return;
    final delay = _config.backoff(_attempt++);
    _timer = Timer(delay, () async {
      _waited += delay;
      await _look(jobId);
      if (state case CheckoutWaiting(:final payment)
          when _waited >= _config.settleTimeout) {
        _stop();
        state = CheckoutTimedOut(payment);
      }
    });
  }

  Future<void> _look(String jobId) async {
    if (_busy) return;
    _busy = true;
    try {
      final result = await _payments.payment(jobId);
      if (result case Ok(value: final payment?)) {
        _apply(payment);
      } else if (state is CheckoutWaiting) {
        // A missed or empty read is retried on the next tick.
        _schedule(jobId);
      }
    } finally {
      _busy = false;
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _attempt = 0;
    _waited = Duration.zero;
  }
}

final jobCheckoutProvider =
    NotifierProvider.autoDispose<JobCheckoutController, JobCheckoutFlow>(
      JobCheckoutController.new,
    );
