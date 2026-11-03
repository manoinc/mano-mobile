import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

// Both ports are mocks until the gateway serves them; reviews are live (myReviewsProvider).

final providerProfileRepositoryProvider = Provider<ProviderProfileRepository>(
  (ref) => MockProviderProfileRepository(),
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

final referralProvider = FutureProvider<ReferralProgram>(
  (ref) => ref.watch(providerProfileRepositoryProvider).referral(),
);

final earningsProvider = FutureProvider.family<EarningsSummary, EarningsPeriod>(
  (ref, period) => ref.watch(earningsRepositoryProvider).summary(period),
);
