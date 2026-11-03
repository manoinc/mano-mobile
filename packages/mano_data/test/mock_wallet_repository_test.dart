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

  const nequi = NequiPayment(
    phone: '3001234567',
    payerEmail: 'ana@example.co',
    acceptedTerms: true,
  );

  test('buying a pack credits coins and bonus and logs a purchase', () async {
    final pack = (await wallet.packs()).firstWhere((p) => p.bonus > 0);
    final result = await wallet.buyPack(pack.id, nequi);
    expect(result.valueOrNull!.coins, pack.totalCoins);
    expect(result.valueOrNull!.step, PurchaseStep.done);
    expect((await wallet.wallet()).balance, 25 + pack.totalCoins);
    expect((await wallet.history()).first.kind, CoinTransactionKind.purchase);
  });

  test('unknown pack is not found', () async {
    expect(
      (await wallet.buyPack('nope', nequi)).failureOrNull,
      isA<DataNotFound>(),
    );
  });

  test('a purchase without the terms is refused and credits nothing', () async {
    final pack = (await wallet.packs()).first;
    const refused = NequiPayment(
      phone: '3001234567',
      payerEmail: 'ana@example.co',
      acceptedTerms: false,
    );
    expect(
      (await wallet.buyPack(pack.id, refused)).failureOrNull,
      isA<DataRejected>(),
    );
    expect((await wallet.wallet()).balance, 25);
  });

  test('offers the terms to accept', () async {
    expect(await wallet.checkoutTerms(), isNotEmpty);
  });
}
