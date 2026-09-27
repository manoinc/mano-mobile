import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('name validation', () {
    test('accepts an ordinary name', () {
      expect(validateGivenName('Ana'), isNull);
      expect(validateFamilyName('Rojas'), isNull);
    });

    test('accepts the accents and ñ that Colombian names actually use', () {
      expect(validateGivenName('José'), isNull);
      expect(validateGivenName('María'), isNull);
      expect(validateFamilyName('Muñoz'), isNull);
      expect(validateFamilyName('Peña Ibáñez'), isNull);
    });

    test("accepts apostrophes and hyphens", () {
      expect(validateFamilyName("O'Brien"), isNull);
      expect(validateFamilyName('García-López'), isNull);
    });

    test('rejects blank and whitespace-only', () {
      expect(validateGivenName(''), FieldProblem.empty);
      expect(validateGivenName('   '), FieldProblem.empty);
    });

    test('rejects a single character', () {
      expect(validateGivenName('A'), FieldProblem.tooShort);
    });

    test('measures length after trimming', () {
      expect(validateGivenName('  Ana  '), isNull);
      expect(validateGivenName('  A  '), FieldProblem.tooShort);
    });

    test('rejects something longer than a name', () {
      expect(validateGivenName('a' * 41), FieldProblem.tooLong);
      expect(validateGivenName('a' * 40), isNull);
    });

    test('rejects digits and punctuation that names do not carry', () {
      expect(validateGivenName('Ana3'), FieldProblem.invalidCharacters);
      expect(validateGivenName('Ana@'), FieldProblem.invalidCharacters);
      expect(validateFamilyName('<script>'), FieldProblem.invalidCharacters);
    });
  });

  group('address validation', () {
    test('accepts a Colombian address, digits and # included', () {
      expect(validateAddress('Calle 12 #3-45'), isNull);
      expect(validateAddress('Carrera 7 No. 71-21, Apto 801'), isNull);
    });

    test('rejects blank', () {
      expect(validateAddress(''), FieldProblem.empty);
      expect(validateAddress('   '), FieldProblem.empty);
    });

    test('rejects something too short to be an address', () {
      expect(validateAddress('C 1'), FieldProblem.tooShort);
    });

    test('rejects something longer than an address', () {
      expect(validateAddress('a' * 121), FieldProblem.tooLong);
      expect(validateAddress('a' * 120), isNull);
    });
  });
}
