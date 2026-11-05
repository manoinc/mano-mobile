import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../offline_marketplace_provider.dart';
import '../session_providers.dart';

// Live on D6 (billing).
final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? ref.watch(mockWalletProvider)
      : GatewayWalletRepository(ref.watch(gatewayTransportProvider)),
);

/// The offline wallet, shared so a mock lead purchase pays from it.
final mockWalletProvider = Provider((ref) => MockWalletRepository());

final walletProvider = FutureProvider<Wallet>(
  (ref) => ref.watch(walletRepositoryProvider).wallet(),
);

final walletHistoryProvider = FutureProvider<List<CoinTransaction>>(
  (ref) => ref.watch(walletRepositoryProvider).history(),
);

final coinPacksProvider = FutureProvider<List<CoinPack>>(
  (ref) => ref.watch(walletRepositoryProvider).packs(),
);

/// What a project lead costs, by category.
final leadPricesProvider = FutureProvider<LeadPricing>(
  (ref) => ref.watch(walletRepositoryProvider).leadPrices(),
);

/// What the payer accepts before buying; a failure is an error state.
final checkoutTermsProvider = FutureProvider<List<CheckoutTerm>>(
  (ref) async =>
      _orThrow(await ref.watch(walletRepositoryProvider).checkoutTerms()),
);

/// The banks PSE can charge.
final pseBanksProvider = FutureProvider<List<Bank>>(
  (ref) async => _orThrow(await ref.watch(walletRepositoryProvider).pseBanks()),
);

T _orThrow<T>(Result<T, DataFailure> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

/// Refetches balance and history after any coin movement.
void refreshWallet(Ref ref) => ref
  ..invalidate(walletProvider)
  ..invalidate(walletHistoryProvider);
