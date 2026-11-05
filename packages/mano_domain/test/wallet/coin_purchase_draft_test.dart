import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  const base = CoinPurchaseDraft(
    packId: 'pack-25',
    payerEmail: 'andres@mano.test',
    termsAccepted: true,
  );
  final nequi = base.copyWith(
    method: CoinPurchaseMethod.nequi,
    phone: '300 123 4567',
  );
  final pse = base.copyWith(
    method: CoinPurchaseMethod.pse,
    bankCode: '1007',
    legalIdType: LegalIdType.cc,
    legalId: '1.020.304.050',
  );

  test('a complete Nequi purchase is valid with the phone normalised', () {
    expect(nequi.isValid, isTrue);
    expect(nequi.nequiPhone, '3001234567');
  });

  test('a complete PSE purchase is valid with the document cleaned', () {
    expect(pse.isValid, isTrue);
    expect(pse.personType, PsePersonType.natural);
    expect(pse.cleanLegalId, '1020304050');
  });

  test('a pack and a method are required', () {
    expect(
      base.copyWith(packId: '').problems,
      containsAll([CoinPurchaseProblem.noPack, CoinPurchaseProblem.noMethod]),
    );
  });

  test('Nequi needs a Colombian mobile', () {
    for (final bad in ['', '200 123 4567', '30012345']) {
      expect(
        nequi.copyWith(phone: bad).problems,
        {CoinPurchaseProblem.invalidPhone},
        reason: bad,
      );
    }
  });

  test('Nequi ignores the PSE fields', () {
    expect(nequi.copyWith(legalId: 'x').isValid, isTrue);
  });

  test('PSE needs a bank and a document that fits its type', () {
    expect(pse.copyWith(bankCode: '').problems, {CoinPurchaseProblem.noBank});
    expect(
      pse.copyWith(legalIdType: LegalIdType.nit, legalId: '123').problems,
      {CoinPurchaseProblem.invalidLegalId},
    );
    expect(
      pse.copyWith(
        personType: PsePersonType.juridical,
        legalIdType: LegalIdType.nit,
        legalId: '900.123.456-7',
      ).isValid,
      isTrue,
    );
  });

  test('the payer email must look like one', () {
    expect(
      nequi.copyWith(payerEmail: 'andres').problems,
      {CoinPurchaseProblem.invalidPayerEmail},
    );
  });

  test('the checkout terms must be accepted', () {
    expect(
      nequi.copyWith(termsAccepted: false).problems,
      {CoinPurchaseProblem.termsNotAccepted},
    );
  });

  test('every purchase step names the payment it belongs to', () {
    const steps = <CoinPurchase>[
      AwaitingApproval(paymentId: 'p1', coins: 28),
      BankRedirect(paymentId: 'p1', coins: 28, url: 'https://bank.test/pay'),
      PurchasePending(paymentId: 'p1', coins: 28),
      PurchaseCompleted(paymentId: 'p1', coins: 28),
    ];
    expect(steps.map((s) => s.paymentId).toSet(), {'p1'});
    expect(steps.where((s) => s.isSettled), hasLength(1));
  });
}
