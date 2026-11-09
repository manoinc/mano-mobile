import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('a Colombian mobile in E.164', () {
    test('adds +57 to ten digits, whatever the separators', () {
      expect(colombianE164('300 123 4567'), '+573001234567');
      expect(colombianE164('+57 (300) 123-4567'), '+573001234567');
    });

    test('is null for anything that is not a mobile', () {
      expect(colombianE164('601 123 4567'), isNull);
      expect(colombianE164('30012'), isNull);
    });
  });

  group('a one-time code', () {
    test('is six digits', () {
      expect(isWellFormedOtp('123456'), isTrue);
      expect(isWellFormedOtp(' 123456 '), isTrue);
      expect(isWellFormedOtp('12345'), isFalse);
      expect(isWellFormedOtp('12a456'), isFalse);
    });
  });

  test('a challenge remembers the number it was sent to', () {
    const challenge = OtpChallenge(
      deviceId: 'd',
      preAuthSessionId: 'p',
      phone: '+573001234567',
    );

    expect(challenge.maskedPhone, '+57 300 *** 4567');
  });

  test('a wrong code says how many tries are left', () {
    const failure = InvalidCode(attemptsLeft: 2);

    expect(failure.attemptsLeft, 2);
    expect(failure, isA<AuthFailure>());
  });
}
