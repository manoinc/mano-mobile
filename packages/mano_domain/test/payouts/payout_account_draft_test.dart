import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  const holder = PayoutAccountDraft(
    holderName: 'Andrés Castro',
    holderEmail: 'andres@mano.test',
    legalIdType: LegalIdType.cc,
    legalId: '1020304050',
  );
  final nequi = holder.copyWith(
    method: PayoutMethod.nequi,
    phone: '300 123 4567',
  );
  final bank = holder.copyWith(
    method: PayoutMethod.bank,
    bankCode: '1007',
    accountType: BankAccountType.savings,
    accountNumber: '123-456789-01',
  );

  group('Nequi', () {
    test('a Colombian mobile is ten digits starting with 3', () {
      expect(nequi.isValid, isTrue);
      expect(nequi.destination, const NequiDestination(phone: '3001234567'));
      for (final bad in ['', '200 123 4567', '300123456', '30012345678']) {
        expect(
          nequi.copyWith(phone: bad).problems,
          contains(PayoutAccountProblem.invalidPhone),
          reason: bad,
        );
      }
    });

    test('accepts the +57 prefix', () {
      expect(nequi.copyWith(phone: '+57 300 123 4567').isValid, isTrue);
    });

    test('ignores bank fields', () {
      expect(nequi.copyWith(accountNumber: 'abc').isValid, isTrue);
    });
  });

  group('Bank', () {
    test('a known bank, a type and a numeric account', () {
      expect(bank.isValid, isTrue);
      expect(
        bank.destination,
        const BankDestination(
          bankCode: '1007',
          accountType: BankAccountType.savings,
          accountNumber: '12345678901',
        ),
      );
    });

    test('a bank must be picked; the server list decides which', () {
      expect(
        bank.copyWith(bankCode: '').problems,
        contains(PayoutAccountProblem.noBank),
      );
      expect(bank.copyWith(bankCode: '9999').isValid, isTrue);
    });

    test('an account type is required', () {
      expect(
        holder
            .copyWith(
              method: PayoutMethod.bank,
              bankCode: '1007',
              accountNumber: '12345678',
            )
            .problems,
        contains(PayoutAccountProblem.noAccountType),
      );
    });

    test('the account number is digits only, 6 to 20 of them', () {
      for (final bad in ['', '12345', '12a456789', '1' * 21]) {
        expect(
          bank.copyWith(accountNumber: bad).problems,
          contains(PayoutAccountProblem.invalidAccountNumber),
          reason: bad,
        );
      }
    });
  });

  group('Account holder', () {
    test('a method must be chosen', () {
      expect(holder.problems, contains(PayoutAccountProblem.noMethod));
    });

    test('a name is required', () {
      expect(
        nequi.copyWith(holderName: ' ').problems,
        contains(PayoutAccountProblem.emptyHolderName),
      );
    });

    test('the document fits its type', () {
      PayoutAccountDraft id(LegalIdType type, String value) =>
          nequi.copyWith(legalIdType: type, legalId: value);
      expect(id(LegalIdType.cc, '12345').isValid, isFalse);
      expect(id(LegalIdType.cc, '123456').isValid, isTrue);
      expect(id(LegalIdType.cc, '12345678901').isValid, isFalse);
      expect(id(LegalIdType.nit, '900123456').isValid, isTrue);
      expect(id(LegalIdType.nit, '900.123.456-7').isValid, isTrue);
      expect(id(LegalIdType.nit, '9001').isValid, isFalse);
      expect(id(LegalIdType.pp, 'AB123456').isValid, isTrue);
      expect(id(LegalIdType.ce, '1234567').isValid, isTrue);
      expect(
        id(LegalIdType.cc, '').problems,
        contains(PayoutAccountProblem.invalidLegalId),
      );
    });

    test('an email is required for the payout provider', () {
      expect(
        nequi.copyWith(holderEmail: 'andres@').problems,
        contains(PayoutAccountProblem.invalidHolderEmail),
      );
      expect(
        PayoutAccountProblem.invalidHolderEmail.step,
        PayoutAccountStep.holder,
      );
    });

    test('builds the holder with the document cleaned', () {
      expect(
        nequi
            .copyWith(legalIdType: LegalIdType.nit, legalId: '900.123.456-7')
            .holder,
        const AccountHolder(
          name: 'Andrés Castro',
          email: 'andres@mano.test',
          legalIdType: LegalIdType.nit,
          legalId: '9001234567',
        ),
      );
    });
  });

  test('problems are grouped so each step checks its own', () {
    expect(
      PayoutAccountProblem.invalidPhone.step,
      PayoutAccountStep.destination,
    );
    expect(PayoutAccountProblem.noBank.step, PayoutAccountStep.bank);
    expect(PayoutAccountProblem.invalidLegalId.step, PayoutAccountStep.holder);
  });
}
