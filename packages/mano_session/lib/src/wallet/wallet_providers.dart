import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../offline_marketplace_provider.dart';
import '../session_providers.dart';

// Billing behind the gateway; offline the in-memory mock stands in.
final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? MockWalletRepository()
      : GatewayWalletRepository(ref.watch(gatewayTransportProvider)),
);

final walletProvider = FutureProvider<Wallet>(
  (ref) => ref.watch(walletRepositoryProvider).wallet(),
);

final walletHistoryProvider = FutureProvider<List<CoinTransaction>>(
  (ref) => ref.watch(walletRepositoryProvider).history(),
);

final coinPacksProvider = FutureProvider<List<CoinPack>>(
  (ref) => ref.watch(walletRepositoryProvider).packs(),
);

final checkoutTermsProvider = FutureProvider<List<CheckoutTerm>>(
  (ref) => ref.watch(walletRepositoryProvider).checkoutTerms(),
);

/// Top-ups; each success refreshes the balance and history.
final class WalletActions extends Notifier<void> {
  @override
  void build() {}

  Future<Result<PackPurchase, DataFailure>> buyPack(
    String packId,
    NequiPayment payment,
  ) async {
    final result = await ref
        .read(walletRepositoryProvider)
        .buyPack(packId, payment);
    if (result.isOk) refreshWallet(ref);
    return result;
  }
}

final walletActionsProvider = NotifierProvider<WalletActions, void>(
  WalletActions.new,
);

/// Refetches balance and history after any coin movement.
void refreshWallet(Ref ref) => ref
  ..invalidate(walletProvider)
  ..invalidate(walletHistoryProvider);
