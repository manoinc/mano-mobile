import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
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

  test('any country keeps its dial code and the last four digits', () {
    OtpChallenge sentTo(String phone) =>
        OtpChallenge(deviceId: 'd', preAuthSessionId: 'p', phone: phone);

    expect(sentTo('+525512345678').maskedPhone, '+52 551 *** 5678');
    expect(sentTo('+593991234567').maskedPhone, '+593 *** 4567');
    expect(sentTo('+34612345678').maskedPhone, '+34 *** 5678');
    expect(sentTo('+4915112345678').maskedPhone, '+*** 5678');
  });

  test('a wrong code says how many tries are left', () {
    const failure = InvalidCode(attemptsLeft: 2);

    expect(failure.attemptsLeft, 2);
    expect(failure, isA<AuthFailure>());
  });
}
