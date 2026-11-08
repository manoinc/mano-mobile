import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

void main() {
  final now = DateTime(2026, 10, 11, 12);
  late MockWalletRepository wallet;
  setUp(() => wallet = MockWalletRepository(now: () => now));

  test(
    'starts with 25 coins and a history that adds up, newest first',
    () async {
      expect((await wallet.wallet()).balance, 25);
      final history = await wallet.history();
      expect(history.fold<int>(0, (sum, t) => sum + t.amount), 25);
      expect(
        history.any((t) => t.kind == CoinTransactionKind.referralBonus),
        isTrue,
      );
      expect(history.first.at.isAfter(history.last.at), isTrue);
    },
  );

  const draft = CoinPurchaseDraft(
    packId: 'pack-50',
    method: CoinPurchaseMethod.nequi,
    phone: '3001234567',
    payerEmail: 'andres@mano.test',
    termsAccepted: true,
  );

  test(
    'a Nequi purchase awaits approval, then credits on a later read',
    () async {
      final result = await wallet.buyPack(draft);
      expect(result.valueOrNull, isA<AwaitingApproval>());
      expect(result.valueOrNull!.coins, 55);
      expect((await wallet.wallet()).balance, 25 + 55);
      expect((await wallet.history()).first.kind, CoinTransactionKind.purchase);
    },
  );

  test('a PSE purchase sends the payer to the bank', () async {
    final result = await wallet.buyPack(
      draft.copyWith(
        method: CoinPurchaseMethod.pse,
        bankCode: '1007',
        legalId: '1020304050',
      ),
    );
    expect((result.valueOrNull! as BankRedirect).url, startsWith('https://'));
  });

  test('coins are not credited before the purchase is read back', () async {
    await wallet.buyPack(draft);
    expect(
      (await wallet.history()).first.kind,
      isNot(CoinTransactionKind.purchase),
    );
  });

  test('an invalid draft is rejected and an unknown pack not found', () async {
    expect(
      (await wallet.buyPack(draft.copyWith(termsAccepted: false)))
          .failureOrNull,
      isA<DataRejected>(),
    );
    expect(
      (await wallet.buyPack(draft.copyWith(packId: 'nope'))).failureOrNull,
      isA<DataNotFound>(),
    );
  });

  test('seeded lead spends read as project contacts', () async {
    final spends = (await wallet.history()).where(
      (t) => t.kind == CoinTransactionKind.leadSpend,
    );
    expect(spends.map((t) => t.label).toSet(), {'Contacto de proyecto'});
  });

  test('a lead spend debits the balance, never below zero', () async {
    expect(wallet.spendOnLead(3).valueOrNull, const Wallet(balance: 22));
    expect(wallet.spendOnLead(23).failureOrNull, const InsufficientCoins());
    expect((await wallet.wallet()).balance, 22);
  });

  test('offers the launch packs, cheapest first', () async {
    expect(await wallet.packs(), const [
      CoinPack(id: 'pack-20', coins: 20, priceCop: 20000),
      CoinPack(id: 'pack-50', coins: 50, priceCop: 50000, bonus: 5),
      CoinPack(id: 'pack-100', coins: 100, priceCop: 100000, bonus: 20),
    ]);
  });

  test('prices leads with the launch table', () async {
    expect(await wallet.leadPrices(), LeadPricing.launch);
  });

  test('offers checkout terms and PSE banks', () async {
    expect((await wallet.checkoutTerms()).valueOrNull, isNotEmpty);
    expect((await wallet.pseBanks()).valueOrNull, isNotEmpty);
  });
}
