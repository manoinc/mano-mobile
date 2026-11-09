import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mano_session/mano_session.dart';

// The default mock repositories are fresh per container, so most tests need no overrides.

/// When the mock job fixtures start: `days` from today at `hour`.
DateTime mockJobStart(int days, int hour) {
  final today = DateTime.now();
  return DateTime(today.year, today.month, today.day + days, hour);
}

List<Override> emptyActivity() => [
  myJobsProvider.overrideWith((ref) async => const <Job>[]),
  myServiceRequestsProvider.overrideWith(
    (ref) async => const <ServiceRequest>[],
  ),
];

List<Override> failingActivity() => [
  myJobsProvider.overrideWith((ref) async => throw StateError('offline')),
  myServiceRequestsProvider.overrideWith(
    (ref) async => throw StateError('offline'),
  ),
];

/// Every job reads as paid, settled through billing.
List<Override> paidJobs() => [
  jobPaymentProvider.overrideWith(
    (ref, jobId) async => JobPayment(
      paymentId: 'pay-$jobId',
      jobId: jobId,
      amount: 120000,
      feeAmount: 6000,
      status: JobPaymentStatus.completed,
    ),
  ),
];
