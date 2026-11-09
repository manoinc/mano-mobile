import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../home/greeting_name.dart';
import '../offline_marketplace_provider.dart';
import '../session_notifier.dart';
import '../session_providers.dart';

// Live on D2 for name, contact, zones, standing and code; bio, skills and photos stay in memory.

/// One in-memory profile, so edits show on Perfil.
final mockProviderProfileProvider = Provider(
  (ref) => MockProviderProfileRepository(),
);

/// Bio, skills and portfolio, which no backend stores yet; blank, never the fixture.
final localProviderDetailsProvider = Provider(
  (ref) => MockProviderProfileRepository(
    initial: const ProviderProfile(
      party: Party(id: '', displayName: '', photoUrl: ''),
      bio: '',
      zones: [],
      yearsExperience: 0,
      verified: false,
    ),
  ),
);

final _liveProviderProfileProvider = Provider((ref) {
  final details = ref.watch(localProviderDetailsProvider);
  return GatewayProviderProfileRepository(
    ref.watch(gatewayTransportProvider),
    details: details,
    detailsEditor: details,
    seedName: greetingName(ref.watch(currentUserProvider)) ?? '',
  );
});

final providerProfileRepositoryProvider = Provider<ProviderProfileRepository>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? ref.watch(mockProviderProfileProvider)
      : ref.watch(_liveProviderProfileProvider),
);

/// Saves through whichever repository [providerProfileRepositoryProvider] reads.
final providerProfileEditorProvider = Provider<ProviderProfileEditor>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? ref.watch(mockProviderProfileProvider)
      : ref.watch(_liveProviderProfileProvider),
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
