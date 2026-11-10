import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('masks a Colombian mobile with or without +57', () {
    expect(maskedMobile('+573010000101'), '+57 301 *** 0101');
    expect(maskedMobile('301 000 0101'), '+57 301 *** 0101');
  });

  test('masks other countries by dial code, keeps local non-mobiles and blank as typed', () {
    expect(maskedMobile('+1 555 0100'), '+1 *** 0100');
    expect(maskedMobile('+525512345678'), '+52 551 *** 5678');
    expect(maskedMobile('601 555 0100'), '601 555 0100');
    expect(maskedMobile('  '), '');
  });
}
