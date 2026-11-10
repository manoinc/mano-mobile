import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/payouts/payout_labels.dart';
import 'package:mano_session/mano_session.dart';

const _banks = [
  Bank(code: '1007', name: 'Bancolombia'),
  Bank(code: '1051', name: 'Davivienda'),
];

BankDestination _bank(String code) => BankDestination(
  bankCode: code,
  accountType: BankAccountType.savings,
  accountNumber: '12345678',
);

void main() {
  test('Nequi and Bancolombia accounts show their logos', () {
    expect(
      payoutLogoAsset(const NequiDestination(phone: '3001234567'), _banks),
      'assets/payments/nequi.png',
    );
    expect(
      payoutLogoAsset(_bank('1007'), _banks),
      'assets/payments/bancolombia.png',
    );
  });

  test('other banks have no logo yet', () {
    expect(payoutLogoAsset(_bank('1051'), _banks), isNull);
  });
}
