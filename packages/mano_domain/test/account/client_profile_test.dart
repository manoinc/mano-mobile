import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  const valid = ClientProfile(
    displayName: 'Ana María Rojas',
    phone: '300 123 4567',
    email: 'ana@mano.co',
  );

  test('a complete profile has no problems', () {
    expect(valid.problems, isEmpty);
  });

  test('each field reports its own problem', () {
    const blank = ClientProfile();
    expect(blank.problems, {
      ClientProfileField.displayName: FieldProblem.empty,
      ClientProfileField.phone: FieldProblem.empty,
    });
    expect(valid.copyWith(email: 'ana@').problems, {
      ClientProfileField.email: FieldProblem.malformed,
    });
    expect(valid.copyWith(displayName: 'A1').problems, {
      ClientProfileField.displayName: FieldProblem.invalidCharacters,
    });
  });

  test('a phone account saves without an email', () {
    expect(valid.copyWith(email: '').problems, isEmpty);
  });

  test('a full name may run longer than a given name', () {
    expect(validateFullName('a' * 60), isNull);
    expect(validateFullName('a' * 61), FieldProblem.tooLong);
  });

  test('copyWith keeps or replaces the photo', () {
    final withPhoto = valid.copyWith(photoUrl: () => 'https://x/p.png');
    expect(withPhoto.photoUrl, 'https://x/p.png');
    expect(withPhoto.copyWith(phone: '3001112233').photoUrl, 'https://x/p.png');
    expect(withPhoto.copyWith(photoUrl: () => null).photoUrl, isNull);
  });

  test('profiles with the same fields are equal', () {
    expect(valid, valid.copyWith());
    expect(valid == valid.copyWith(phone: '3009998877'), isFalse);
  });

  group('mobile phone', () {
    test('accepts a Colombian mobile, with spaces, dashes or +57', () {
      expect(validateMobilePhone('3001234567'), isNull);
      expect(validateMobilePhone('300 123 4567'), isNull);
      expect(validateMobilePhone('300-123-4567'), isNull);
      expect(validateMobilePhone('+57 300 123 4567'), isNull);
    });

    test('refuses blanks, landlines and short numbers', () {
      expect(validateMobilePhone('  '), FieldProblem.empty);
      expect(validateMobilePhone('6011234567'), FieldProblem.malformed);
      expect(validateMobilePhone('300123'), FieldProblem.malformed);
      expect(validateMobilePhone('300abc4567'), FieldProblem.malformed);
    });

    test('digits only, without the country code', () {
      expect(mobileDigits('+57 300-123 4567'), '3001234567');
    });
  });
}
