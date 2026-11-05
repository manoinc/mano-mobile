import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import 'billing_config.dart';
import 'coin_purchase_flow.dart';
import 'wallet_providers.dart';

/// Buys a pack, then watches the balance until the coins land or the wait runs out.
final class CoinPurchaseController extends Notifier<CoinPurchaseFlow> {
  Timer? _timer;
  CoinPurchaseDraft? _draft;
  var _startBalance = 0;
  var _polls = 0;
  var _busy = false;

  @override
  CoinPurchaseFlow build() {
    ref.onDispose(_stop);
    return const PurchaseIdle();
  }

  WalletRepository get _wallet => ref.read(walletRepositoryProvider);

  Future<void> buy(CoinPurchaseDraft draft) async {
    _stop();
    if (!draft.isValid) {
      state = PurchaseFailed(DataRejected(reason: '${draft.problems}'));
      return;
    }
    _draft = draft;
    state = const PurchaseSubmitting();
    final before = await _balance();
    if (before == null) {
      state = const PurchaseFailed(DataUnavailable(detail: 'wallet unread'));
      return;
    }
    _startBalance = before;
    await _apply(await _wallet.buyPack(draft));
  }

  /// Looks now, e.g. on app resume or "Ya pagué"; also revives a timed-out wait.
  Future<void> checkNow() async {
    final step = switch (state) {
      PurchaseWaiting(:final step) || PurchaseTimedOut(:final step) => step,
      _ => null,
    };
    if (step == null) return;
    await _look(step, countsTowardTimeout: false);
  }

  void reset() {
    _stop();
    state = const PurchaseIdle();
  }

  Future<void> _apply(Result<CoinPurchase, DataFailure> result) async {
    switch (result) {
      case Err(:final failure):
        _stop();
        state = PurchaseFailed(failure);
      case Ok(value: PurchaseCompleted(:final coins)):
        _credited(coins, await _balance() ?? _startBalance + coins);
      case Ok(:final value):
        state = PurchaseWaiting(value);
        _timer ??= Timer.periodic(
          ref.read(billingConfigProvider).pollInterval,
          (_) => _tick(),
        );
    }
  }

  void _tick() {
    if (state case PurchaseWaiting(:final step)) {
      _look(step, countsTowardTimeout: true);
    }
  }

  Future<void> _look(
    CoinPurchase step, {
    required bool countsTowardTimeout,
  }) async {
    if (_busy) return;
    _busy = true;
    try {
      // Billing hands the bank's link out later; asking again returns the live payment.
      if (step is PurchasePending && _draft != null) {
        await _apply(await _wallet.buyPack(_draft!));
        if (state is! PurchaseWaiting) return;
      }
      final balance = await _balance();
      if (balance != null && balance > _startBalance) {
        return _credited(balance - _startBalance, balance);
      }
      if (countsTowardTimeout &&
          ++_polls >= ref.read(billingConfigProvider).maxPolls) {
        _stop();
        state = PurchaseTimedOut(step);
      }
    } finally {
      _busy = false;
    }
  }

  void _credited(int coins, int balance) {
    _stop();
    state = PurchaseCredited(coins: coins, balance: balance);
    refreshWallet(ref);
  }

  Future<int?> _balance() async {
    try {
      return (await _wallet.wallet()).balance;
    } on Object {
      // A missed read is retried on the next tick.
      return null;
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _polls = 0;
  }
}

final coinPurchaseProvider =
    NotifierProvider<CoinPurchaseController, CoinPurchaseFlow>(
      CoinPurchaseController.new,
    );
