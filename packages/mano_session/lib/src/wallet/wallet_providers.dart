import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

// The gateway has no wallet yet, so the in-memory mock stands in.
final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => MockWalletRepository(),
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

/// Top-ups; each success refreshes the balance and history.
final class WalletActions extends Notifier<void> {
  @override
  void build() {}

  Future<Result<Wallet, DataFailure>> buyPack(String packId) async {
    final result = await ref.read(walletRepositoryProvider).buyPack(packId);
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
