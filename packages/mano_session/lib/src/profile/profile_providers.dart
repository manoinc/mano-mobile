import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

// Both ports are mocks until the gateway serves them (docs/develop/backend-contract.md).

/// One in-memory profile, so edits show on Perfil.
final mockProviderProfileProvider = Provider(
  (ref) => MockProviderProfileRepository(),
);

final providerProfileRepositoryProvider = Provider<ProviderProfileRepository>(
  (ref) => ref.watch(mockProviderProfileProvider),
);

final earningsRepositoryProvider = Provider<EarningsRepository>(
  (ref) => MockEarningsRepository(),
);

final providerProfileProvider = FutureProvider<ProviderProfile>(
  (ref) => ref.watch(providerProfileRepositoryProvider).profile(),
);

final providerStatsProvider = FutureProvider<ProviderStats>(
  (ref) => ref.watch(providerProfileRepositoryProvider).stats(),
);

final providerReviewsProvider = FutureProvider<List<Review>>(
  (ref) => ref.watch(providerProfileRepositoryProvider).reviews(),
);

final referralProvider = FutureProvider<ReferralProgram>(
  (ref) => ref.watch(providerProfileRepositoryProvider).referral(),
);

final earningsProvider = FutureProvider.family<EarningsSummary, EarningsPeriod>(
  (ref, period) => ref.watch(earningsRepositoryProvider).summary(period),
);
