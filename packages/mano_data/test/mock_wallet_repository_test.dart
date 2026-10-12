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

  test('buying a pack credits coins and bonus and logs a purchase', () async {
    final pack = (await wallet.packs()).firstWhere((p) => p.bonus > 0);
    final result = await wallet.buyPack(pack.id);
    expect(result.valueOrNull!.balance, 25 + pack.totalCoins);
    expect((await wallet.history()).first.kind, CoinTransactionKind.purchase);
  });

  test('unknown pack is not found', () async {
    expect((await wallet.buyPack('nope')).failureOrNull, isA<DataNotFound>());
  });

  test('spending debits and logs against the request', () async {
    final result = await wallet.spendForLead('request-1', 3, label: 'Limpieza');
    expect(result.valueOrNull!.amount, -3);
    expect((await wallet.wallet()).balance, 22);
    expect((await wallet.history()).first.requestId, 'request-1');
  });

  test('spending more than the balance fails and changes nothing', () async {
    final result = await wallet.spendForLead('r', 26, label: 'x');
    expect(
      result.failureOrNull,
      const InsufficientCoins(needed: 26, available: 25),
    );
    expect((await wallet.wallet()).balance, 25);
  });

  test('refunding gives back the spend once', () async {
    await wallet.spendForLead('request-1', 3, label: 'x');
    expect((await wallet.refundLead('request-1')).valueOrNull!.balance, 25);
    expect((await wallet.history()).first.kind, CoinTransactionKind.refund);
    expect(
      (await wallet.refundLead('request-1')).failureOrNull,
      isA<DataNotFound>(),
    );
  });
}
