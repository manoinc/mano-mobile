import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('the launch prices each canonical category', () {
    const prices = LeadPricing.launch;
    expect(prices.defaultCoins, 5);
    expect(prices.costFor(ServiceCategories.cleaning), 4);
    expect(prices.costFor(ServiceCategories.gardening), 4);
    expect(prices.costFor(ServiceCategories.plumbing), 5);
    expect(prices.costFor(ServiceCategories.electrical), 5);
    expect(prices.costFor(ServiceCategories.painting), 6);
  });

  test('folds spellings and falls back to the default cost', () {
    const prices = LeadPricing(
      defaultCoins: 5,
      prices: {ServiceCategories.plumbing: 7},
    );
    expect(prices.costFor('Plomería'), 7);
    expect(prices.costFor('carpintería'), 5);
  });

  test('lead pricing compares by value', () {
    expect(
      const LeadPricing(defaultCoins: 2, prices: {'plumbing': 3}),
      LeadPricing(defaultCoins: 2, prices: {'plumbing': 3}),
    );
  });

  test('wallet affords a cost up to its balance', () {
    const wallet = Wallet(balance: 3);
    expect(wallet.canAfford(3), isTrue);
    expect(wallet.canAfford(4), isFalse);
  });

  test('transactions are credits or debits by sign', () {
    final spend = CoinTransaction(
      id: 't1',
      kind: CoinTransactionKind.leadSpend,
      amount: -3,
      label: 'Lead',
      at: DateTime(2026, 10, 1),
      requestId: 'request-1',
    );
    expect(spend.isCredit, isFalse);
    expect(spend, spend);
  });

  test('insufficient coins compare by type and have a message', () {
    const failure = InsufficientCoins();
    expect(failure, const InsufficientCoins());
    expect(failure.message, isNotEmpty);
  });

  test('pack totals include the bonus', () {
    const pack = CoinPack(id: 'p', coins: 20, priceCop: 40000, bonus: 5);
    expect(pack.totalCoins, 25);
  });
}
