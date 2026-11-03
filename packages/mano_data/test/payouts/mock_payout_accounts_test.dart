import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

void main() {
  const holder = AccountHolder(
    name: 'Andrés Castro',
    legalIdType: LegalIdType.cc,
    legalId: '1020304050',
  );
  const nequi = NequiDestination(phone: '3001234567');
  const bank = BankDestination(
    bankCode: '1007',
    accountType: BankAccountType.savings,
    accountNumber: '12345678',
  );

  late MockPayoutAccounts accounts;

  setUp(() => accounts = MockPayoutAccounts());

  test('starts with no account', () async {
    expect((await accounts.current()).valueOrNull, isNull);
  });

  test('a registered account becomes the current one', () async {
    final registered = (await accounts.register(
      destination: nequi,
      holder: holder,
    )).valueOrNull!;

    final current = (await accounts.current()).valueOrNull!;
    expect(current.id, registered.id);
    expect(current.destination, nequi);
    expect(current.holder, holder);
  });

  test('registering again replaces it', () async {
    await accounts.register(destination: nequi, holder: holder);
    await accounts.register(destination: bank, holder: holder);
    expect((await accounts.current()).valueOrNull!.destination, bank);
  });

  test('removing leaves none; an unknown id is not found', () async {
    final a = (await accounts.register(
      destination: nequi,
      holder: holder,
    )).valueOrNull!;

    expect((await accounts.remove('nope')).failureOrNull, isA<DataNotFound>());
    expect((await accounts.remove(a.id)).isOk, isTrue);
    expect((await accounts.current()).valueOrNull, isNull);
  });
}
