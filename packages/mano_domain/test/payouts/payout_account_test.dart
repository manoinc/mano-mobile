import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  const holder = AccountHolder(
    name: 'Andrés Castro',
    legalIdType: LegalIdType.cc,
    legalId: '1020304050',
  );

  test('the last four digits of the phone or the account', () {
    expect(const NequiDestination(phone: '3001234567').lastDigits, '4567');
    expect(
      const BankDestination(
        bankCode: '1007',
        accountType: BankAccountType.checking,
        accountNumber: '98765432',
      ).lastDigits,
      '5432',
    );
    expect(
      const PayoutAccount(
        id: 'a',
        destination: NequiDestination(phone: '3001234567'),
        holder: holder,
      ).destination.lastDigits,
      '4567',
    );
  });

  test('Colombian banks have unique codes and names', () {
    final codes = ColombianBanks.all.map((b) => b.code).toSet();
    expect(codes, hasLength(ColombianBanks.all.length));
    expect(ColombianBanks.byCode('1007')?.name, 'Bancolombia');
    expect(ColombianBanks.byCode('nope'), isNull);
  });

  test('normalizes a Colombian mobile number', () {
    expect(normalizeColombianMobile('+57 (300) 123-4567'), '3001234567');
    expect(normalizeColombianMobile('6011234567'), isNull);
  });
}
