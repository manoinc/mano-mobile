import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('prices each canonical category', () {
    expect(LeadPricing.costFor(ServiceCategories.cleaning), 2);
    expect(LeadPricing.costFor(ServiceCategories.gardening), 2);
    expect(LeadPricing.costFor(ServiceCategories.plumbing), 3);
    expect(LeadPricing.costFor(ServiceCategories.electrical), 3);
    expect(LeadPricing.costFor(ServiceCategories.painting), 4);
  });

  test('folds spellings and falls back to the default cost', () {
    expect(LeadPricing.costFor('Plomería'), 3);
    expect(LeadPricing.costFor('carpintería'), LeadPricing.defaultCost);
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
