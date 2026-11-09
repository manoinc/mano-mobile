import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

// Mock until STREAM-03 wires payJob/jobPayment.
final jobPaymentRepositoryProvider = Provider<JobPaymentRepository>(
  (ref) => MockJobPaymentRepository(),
);

/// A job's payment, or null when it has not been paid; a failure is an error state.
final jobPaymentProvider = FutureProvider.family<JobPayment?, String>((
  ref,
  jobId,
) async {
  final result = await ref.watch(jobPaymentRepositoryProvider).payment(jobId);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});
