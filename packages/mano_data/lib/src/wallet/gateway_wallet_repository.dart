import 'package:mano_domain/mano_domain.dart';

import '../billing/billing_documents.dart';
import '../billing/billing_json.dart';
import '../gateway/gateway_failure.dart';
import '../gateway/gateway_json.dart';
import '../gateway/gateway_transport.dart';

/// [WalletRepository] over D6 (mano-billing).
final class GatewayWalletRepository implements WalletRepository {
  GatewayWalletRepository(this._transport);

  final GatewayTransport _transport;

  @override
  Future<Wallet> wallet() async {
    final data = await _transport.run(coinWalletQuery);
    final json = data['myCoinWallet'] as Map<String, dynamic>;
    return Wallet(balance: json['balance'] as int);
  }

  @override
  Future<List<CoinTransaction>> history() async {
    final data = await _transport.run(coinMovementsQuery);
    return [
      for (final json in pageItems(data['myCoinMovements']))
        coinMovementFromJson(json),
    ];
  }

  @override
  Future<List<CoinPack>> packs() async {
    final data = await _transport.run(coinPacksQuery);
    return [
      for (final json in data['coinPacks'] as List<dynamic>)
        coinPackFromJson(json as Map<String, dynamic>),
    ];
  }

  @override
  Future<Result<CoinPurchase, DataFailure>> buyPack(
    CoinPurchaseDraft draft,
  ) async {
    if (!draft.isValid) {
      return Err(DataRejected(reason: 'invalid draft: ${draft.problems}'));
    }
    final result = await guardGateway(
      () => _transport.run(
        buyCoinPackMutation,
        variables: buyCoinPackVariables(draft),
      ),
    );
    return switch (result) {
      Ok(:final value) => coinPurchaseFromJson(
        value['buyCoinPack'] as Map<String, dynamic>,
      ),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<Result<List<CheckoutTerm>, DataFailure>> checkoutTerms() =>
      guardGateway(() async {
        final data = await _transport.run(checkoutTermsQuery);
        return [
          for (final json in data['checkoutTerms'] as List<dynamic>)
            termFromJson(json as Map<String, dynamic>),
        ];
      });

  @override
  Future<Result<List<Bank>, DataFailure>> pseBanks() => guardGateway(() async {
    final data = await _transport.run(pseBanksQuery);
    return [
      for (final json in data['pseBanks'] as List<dynamic>)
        bankFromJson(json as Map<String, dynamic>),
    ];
  });

  @override
  Future<LeadPricing> leadPrices() async {
    final data = await _transport.run(leadPricesQuery);
    return leadPricingFromJson(data['leadPrices'] as Map<String, dynamic>);
  }
}
