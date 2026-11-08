import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

import 'fake_wallet.dart';

const _draft = CoinPurchaseDraft(
  packId: 'pack-50',
  method: CoinPurchaseMethod.nequi,
  phone: '3001234567',
  payerEmail: 'andres@mano.test',
  termsAccepted: true,
);

const _config = BillingConfig(
  pollInterval: Duration(seconds: 1),
  settleTimeout: Duration(seconds: 5),
);

const _awaiting = Ok<CoinPurchase, DataFailure>(
  AwaitingApproval(paymentId: 'p1', coins: 55),
);

ProviderContainer _container(FakeWallet wallet) => ProviderContainer.test(
  overrides: [
    walletRepositoryProvider.overrideWithValue(wallet),
    billingConfigProvider.overrideWithValue(_config),
  ],
);

CoinPurchaseFlow _flow(ProviderContainer c) => c.read(coinPurchaseProvider);

CoinPurchaseController _controller(ProviderContainer c) =>
    c.read(coinPurchaseProvider.notifier);

void main() {
  test('awaits approval, then reports the coins once the balance moves', () {
    fakeAsync((async) {
      final wallet = FakeWallet(replies: [_awaiting], creditAfterReads: 2);
      final c = _container(wallet);
      _controller(c).buy(_draft);
      async.flushMicrotasks();

      expect(_flow(c), isA<PurchaseWaiting>());
      expect((_flow(c) as PurchaseWaiting).step, isA<AwaitingApproval>());

      async.elapse(const Duration(seconds: 1));
      expect(_flow(c), isA<PurchaseWaiting>());

      async.elapse(const Duration(seconds: 1));
      final credited = _flow(c) as PurchaseCredited;
      expect(credited.coins, 55);
      expect(credited.balance, 65);
    });
  });

  test('gives up waiting after the timeout, and a later check can land', () {
    fakeAsync((async) {
      final wallet = FakeWallet(replies: [_awaiting], creditAfterReads: 6);
      final c = _container(wallet);
      _controller(c).buy(_draft);
      async.elapse(const Duration(seconds: 6));

      expect(_flow(c), isA<PurchaseTimedOut>());
      expect(wallet.readsSinceBuy, 5);
      async.elapse(const Duration(seconds: 10));
      expect(wallet.readsSinceBuy, 5, reason: 'polling stopped');

      _controller(c).checkNow();
      async.flushMicrotasks();
      expect(_flow(c), isA<PurchaseCredited>());
    });
  });

  test('a completed purchase is credited at once', () {
    fakeAsync((async) {
      final c = _container(
        FakeWallet(
          replies: [const Ok(PurchaseCompleted(paymentId: 'p1', coins: 55))],
        ),
      );
      _controller(c).buy(_draft);
      async.flushMicrotasks();
      expect((_flow(c) as PurchaseCredited).balance, 65);
    });
  });

  test(
    'a pending purchase asks billing again until the bank link is ready',
    () {
      fakeAsync((async) {
        final wallet = FakeWallet(
          replies: [
            const Ok(PurchasePending(paymentId: 'p1', coins: 55)),
            const Ok(
              BankRedirect(
                paymentId: 'p1',
                coins: 55,
                url: 'https://bank.test',
              ),
            ),
          ],
        );
        final c = _container(wallet);
        _controller(c).buy(_draft);
        async.flushMicrotasks();
        expect((_flow(c) as PurchaseWaiting).step, isA<PurchasePending>());

        async.elapse(const Duration(seconds: 1));
        expect(wallet.buys, 2);
        expect((_flow(c) as PurchaseWaiting).step, isA<BankRedirect>());
      });
    },
  );

  test('a refusal is a failure, and reset starts over', () {
    fakeAsync((async) {
      final c = _container(
        FakeWallet(replies: [const Err(DataRejected(reason: 'declined'))]),
      );
      _controller(c).buy(_draft);
      async.flushMicrotasks();
      expect((_flow(c) as PurchaseFailed).failure, isA<DataRejected>());

      _controller(c).reset();
      expect(_flow(c), isA<PurchaseIdle>());
    });
  });

  test('an invalid draft is refused without calling billing', () {
    fakeAsync((async) {
      final wallet = FakeWallet(replies: [_awaiting]);
      final c = _container(wallet);
      _controller(c).buy(_draft.copyWith(termsAccepted: false));
      async.flushMicrotasks();
      expect(_flow(c), isA<PurchaseFailed>());
      expect(wallet.buys, 0);
    });
  });

  test(
    'the default config polls every few seconds for a couple of minutes',
    () {
      const config = BillingConfig.standard;
      expect(config.pollInterval, const Duration(seconds: 3));
      expect(config.maxPolls, 40);
    },
  );
}
