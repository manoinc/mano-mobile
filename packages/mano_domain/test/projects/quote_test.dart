import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
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
