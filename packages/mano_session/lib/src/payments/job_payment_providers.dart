import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../offline_marketplace_provider.dart';
import '../session_providers.dart';

// Live on D6 (billing).
final jobPaymentRepositoryProvider = Provider<JobPaymentRepository>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? ref.watch(mockJobPaymentProvider)
      : GatewayJobPaymentRepository(ref.watch(gatewayTransportProvider)),
);

/// The offline job payments, shared so a payment outlives the screen that made it.
final mockJobPaymentProvider = Provider((ref) => MockJobPaymentRepository());

/// A job's payment, or null when it has not been paid; a failure is an error state.
final jobPaymentProvider = FutureProvider.family<JobPayment?, String>(
  (ref, jobId) async =>
      _orThrow(await ref.watch(jobPaymentRepositoryProvider).payment(jobId)),
);

/// What the payer accepts before paying a job.
final jobCheckoutTermsProvider = FutureProvider<List<CheckoutTerm>>(
  (ref) async =>
      _orThrow(await ref.watch(jobPaymentRepositoryProvider).checkoutTerms()),
);

/// The banks PSE can charge a job to.
final jobPseBanksProvider = FutureProvider<List<Bank>>(
  (ref) async =>
      _orThrow(await ref.watch(jobPaymentRepositoryProvider).pseBanks()),
);

T _orThrow<T>(Result<T, DataFailure> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};
