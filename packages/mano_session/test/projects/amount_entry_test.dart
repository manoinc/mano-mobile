import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  test('typing appends digits to the amount', () {
    expect(typeAmount(null, '1'), 1);
    expect(typeAmount(1, '8'), 18);
    expect(typeAmount(18, '000'), 18000);
  });

  test('leading zeros keep the amount empty', () {
    expect(typeAmount(null, '0'), isNull);
    expect(typeAmount(null, '000'), isNull);
  });

  test('typing stops below a billion pesos', () {
    expect(typeAmount(999999999, '9'), 999999999);
    expect(typeAmount(1000000, '000'), 1000000);
  });

  test('erasing drops the last digit, then empties', () {
    expect(eraseAmount(1800), 180);
    expect(eraseAmount(7), isNull);
    expect(eraseAmount(null), isNull);
  });
}
