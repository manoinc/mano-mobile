import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mano_session/mano_session.dart';

/// Billing as a test scripts it: packs, the buy reply, and when the coins land.
final class ScriptedWallet implements WalletRepository {
  ScriptedWallet({
    required this.reply,
    this.balance = 10,
    this.landsOnRead,
    this.packList = const [
      CoinPack(id: 'pack-a', coins: 12, priceCop: 24000),
      CoinPack(id: 'pack-b', coins: 30, priceCop: 54000, bonus: 5),
    ],
    this.banks = const [Bank(code: '1022', name: 'Banco Unión')],
    this.pricing = LeadPricing.launch,
  });

  Result<CoinPurchase, DataFailure> reply;
  int balance;

  /// The wallet read after a buy that sees the coins; null never lands.
  final int? landsOnRead;
  final List<CoinPack> packList;
  final List<Bank> banks;
  final LeadPricing pricing;

  final drafts = <CoinPurchaseDraft>[];
  var _reads = 0;
  var _owed = 0;

  @override
  Future<Wallet> wallet() async {
    if (_owed > 0 && ++_reads == landsOnRead) {
      balance += _owed;
      _owed = 0;
    }
    return Wallet(balance: balance);
  }

  @override
  Future<Result<CoinPurchase, DataFailure>> buyPack(
    CoinPurchaseDraft draft,
  ) async {
    drafts.add(draft);
    _reads = 0;
    if (reply case Ok(:final value)) _owed = value.coins;
    return reply;
  }

  @override
  Future<List<CoinTransaction>> history() async => const [];

  @override
  Future<List<CoinPack>> packs() async => packList;

  @override
  Future<Result<List<CheckoutTerm>, DataFailure>> checkoutTerms() async =>
      const Ok([
        CheckoutTerm(label: 'Términos de la pasarela', url: 'https://t.test'),
      ]);

  @override
  Future<Result<List<Bank>, DataFailure>> pseBanks() async => Ok(banks);

  @override
  Future<LeadPricing> leadPrices() async => pricing;
}

/// Records the links the app asked to open.
final class FakeLinks {
  final opened = <Uri>[];

  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

/// A wallet, short polling, and recorded links, for the Recargar tests.
List<Override> billingOverrides(ScriptedWallet wallet, FakeLinks links) => [
  walletRepositoryProvider.overrideWithValue(wallet),
  externalLinkOpenerProvider.overrideWithValue(links.open),
  billingConfigProvider.overrideWithValue(
    const BillingConfig(
      pollInterval: Duration(seconds: 1),
      settleTimeout: Duration(seconds: 3),
    ),
  ),
];
