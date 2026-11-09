import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 11, 2);

  group('card number', () {
    test('accepts a Luhn-valid number, spaced or not', () {
      expect(validateCardNumber('4242 4242 4242 4242'), isNull);
      expect(validateCardNumber('5555555555554444'), isNull);
    });

    test('refuses blanks, bad checksums and odd lengths', () {
      expect(validateCardNumber(''), FieldProblem.empty);
      expect(validateCardNumber('4242 4242 4242 4241'), FieldProblem.malformed);
      expect(validateCardNumber('4242'), FieldProblem.malformed);
      expect(validateCardNumber('4242-abcd'), FieldProblem.malformed);
    });

    test('names the brand from the first digits', () {
      expect(cardBrandOf('4242424242424242'), 'Visa');
      expect(cardBrandOf('5555555555554444'), 'Mastercard');
      expect(cardBrandOf('378282246310005'), 'Amex');
      expect(cardBrandOf('6011111111111117'), 'Tarjeta');
    });
  });

  group('expiry', () {
    test('accepts this month and later', () {
      expect(validateCardExpiry('11/26', now: now), isNull);
      expect(validateCardExpiry('01/30', now: now), isNull);
    });

    test('refuses past months and bad shapes', () {
      expect(validateCardExpiry('', now: now), FieldProblem.empty);
      expect(validateCardExpiry('10/26', now: now), FieldProblem.expired);
      expect(validateCardExpiry('13/27', now: now), FieldProblem.malformed);
      expect(validateCardExpiry('1227', now: now), FieldProblem.malformed);
    });

    test('parses MM/AA into a month and a four-digit year', () {
      expect(parseCardExpiry('05/33'), (month: 5, year: 2033));
      expect(parseCardExpiry('13/33'), isNull);
      expect(parseCardExpiry('0533'), isNull);
    });
  });

  group('new methods', () {
    test('a card keeps only its brand and last four digits', () {
      const card = NewCard(number: '4242 4242 4242 4242', expiry: '12/28');
      expect(card.problems(now), isEmpty);
      final stored = card.storedAs('pm-1');
      expect(stored.kind, PaymentKind.card);
      expect(stored.label, 'Visa');
      expect(stored.last4, '4242');
      expect(stored.expiry, (month: 12, year: 2028));
      expect(stored.isDefault, isFalse);
    });

    test('a card reports number and expiry problems', () {
      const card = NewCard(number: '1234', expiry: '01/20');
      expect(card.problems(now), {
        PaymentField.cardNumber: FieldProblem.malformed,
        PaymentField.expiry: FieldProblem.expired,
      });
    });

    test('Nequi is a mobile number', () {
      const nequi = NewNequi(phone: '300 123 4567');
      expect(nequi.problems(now), isEmpty);
      final stored = nequi.storedAs('pm-2');
      expect(stored.kind, PaymentKind.nequi);
      expect(stored.label, 'Nequi');
      expect(stored.last4, '4567');
      expect(stored.expiry, isNull);
      expect(const NewNequi(phone: '601').problems(now), {
        PaymentField.phone: FieldProblem.malformed,
      });
    });
  });

  group('withOneDefaultMethod', () {
    PaymentMethod method(String id, {bool isDefault = false}) => PaymentMethod(
      id: id,
      kind: PaymentKind.card,
      label: 'Visa',
      last4: '4242',
      isDefault: isDefault,
    );

    test('the first becomes the default when none is', () {
      final list = withOneDefaultMethod([method('a'), method('b')]);
      expect(list.map((m) => m.isDefault), [true, false]);
    });

    test('a chosen id wins and moves first', () {
      final list = withOneDefaultMethod([
        method('a', isDefault: true),
        method('b'),
      ], defaultId: 'b');
      expect(list.map((m) => (m.id, m.isDefault)), [('b', true), ('a', false)]);
    });
  });
}
