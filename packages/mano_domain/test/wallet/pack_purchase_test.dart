import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('a purchase compares by value', () {
    const a = PackPurchase(
      paymentId: 'p-1',
      coins: 28,
      step: PurchaseStep.approveInNequi,
    );
    expect(
      a,
      const PackPurchase(
        paymentId: 'p-1',
        coins: 28,
        step: PurchaseStep.approveInNequi,
      ),
    );
    expect(
      a ==
          const PackPurchase(
            paymentId: 'p-1',
            coins: 28,
            step: PurchaseStep.wait,
          ),
      isFalse,
    );
  });

  test('a bought lead is part of a quote\'s identity', () {
    final quote = Quote(
      id: 'q-1',
      projectId: 'p-1',
      projectTitle: 'Baño',
      worker: const Party(id: 'w-1', displayName: 'Ana', photoUrl: ''),
      amountCop: 1000,
      status: QuoteStatus.selected,
      createdAt: DateTime(2026, 11, 3),
    );
    expect(quote.leadPurchased, isFalse);
    final bought = quote.copyWith(leadPurchased: true);
    expect(bought.leadPurchased, isTrue);
    expect(bought == quote, isFalse);
  });
}
