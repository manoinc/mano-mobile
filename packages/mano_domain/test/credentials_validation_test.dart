import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('validateEmail', () {
    test('an empty email is empty', () {
      expect(validateEmail('  '), CredentialProblem.empty);
    });

    test('an email needs a local part, an @ and a dotted domain', () {
      expect(validateEmail('ana'), CredentialProblem.malformedEmail);
      expect(validateEmail('ana@mano'), CredentialProblem.malformedEmail);
      expect(validateEmail('@mano.co'), CredentialProblem.malformedEmail);
      expect(validateEmail('ana @mano.co'), CredentialProblem.malformedEmail);
    });

    test('a well-formed email passes, surrounding spaces aside', () {
      expect(validateEmail(' ana@mano.co '), isNull);
    });
  });

  group('validatePassword', () {
    test('an empty password is empty', () {
      expect(validatePassword(''), CredentialProblem.empty);
    });

    test('fewer than eight characters is too short', () {
      expect(validatePassword('abc123'), CredentialProblem.tooShort);
    });

    test('it needs a letter and a number, as SuperTokens does', () {
      expect(
        validatePassword('abcdefgh'),
        CredentialProblem.needsLetterAndNumber,
      );
      expect(
        validatePassword('12345678'),
        CredentialProblem.needsLetterAndNumber,
      );
    });

    test('eight characters with a letter and a number pass', () {
      expect(validatePassword('mano2026'), isNull);
    });
  });
}
