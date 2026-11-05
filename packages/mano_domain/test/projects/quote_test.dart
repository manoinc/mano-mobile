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

  test('the unlocked contact is part of a quote\'s identity', () {
    final quote = Quote(
      id: 'q-1',
      projectId: 'p-1',
      projectTitle: 'Baño',
      worker: const Party(id: 'w-1', displayName: 'Ana', photoUrl: ''),
      amountCop: 1000,
      status: QuoteStatus.selected,
      createdAt: DateTime(2026, 11, 3),
    );
    expect(quote.clientContact, isNull);
    final unlocked = quote.copyWith(
      clientContact: const ContactInfo(phone: '3001234567'),
    );
    expect(unlocked.clientContact, const ContactInfo(phone: '3001234567'));
    expect(unlocked == quote, isFalse);
  });

  test('a contact with neither phone nor email is empty', () {
    expect(const ContactInfo().isEmpty, isTrue);
    expect(const ContactInfo(email: 'a@b.co').isEmpty, isFalse);
  });
}
