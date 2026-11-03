import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_transport.dart';

/// [WalletRepository] over the gateway's D6 coin operations (mano-billing).
final class GatewayWalletRepository implements WalletRepository {
  const GatewayWalletRepository(this._transport);

  final GatewayTransport _transport;

  static const _walletQuery = '{ myCoinWallet { balance } }';

  static const _historyQuery = '''
query CoinHistory {
  myCoinMovements(page: {first: 50}) { items { id type coins createdAt } }
}''';

  static const _packsQuery =
      '{ coinPacks { id coins bonus price { amount } } }';

  static const _termsQuery = '{ checkoutTerms { label url } }';

  static const _buyMutation = r'''
mutation BuyPack($packId: ID!, $method: PaymentMethodInput!, $payerEmail: String!, $termsAccepted: Boolean!) {
  buyCoinPack(packId: $packId, method: $method, payerEmail: $payerEmail, termsAccepted: $termsAccepted) {
    payment { id coins }
    nextAction { type redirectUrl }
  }
}''';

  @override
  Future<Wallet> wallet() async {
    final data = await _transport.run(_walletQuery);
    final wallet = data['myCoinWallet'] as Map<String, dynamic>;
    return Wallet(balance: wallet['balance'] as int);
  }

  @override
  Future<List<CoinTransaction>> history() async {
    final data = await _transport.run(_historyQuery);
    final page = data['myCoinMovements'] as Map<String, dynamic>;
    return (page['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_movement)
        .toList();
  }

  @override
  Future<List<CoinPack>> packs() async {
    final data = await _transport.run(_packsQuery);
    return (data['coinPacks'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (pack) => CoinPack(
            id: pack['id'] as String,
            coins: pack['coins'] as int,
            bonus: pack['bonus'] as int,
            priceCop: ((pack['price'] as Map<String, dynamic>)['amount'] as num)
                .round(),
          ),
        )
        .toList();
  }

  @override
  Future<List<CheckoutTerm>> checkoutTerms() async {
    final data = await _transport.run(_termsQuery);
    return (data['checkoutTerms'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (term) => CheckoutTerm(
            label: term['label'] as String,
            url: term['url'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<Result<PackPurchase, DataFailure>> buyPack(
    String packId,
    NequiPayment payment,
  ) => guardGateway(() async {
    final data = await _transport.run(
      _buyMutation,
      variables: {
        'packId': packId,
        'method': {
          'wallet': {'phone': payment.phone},
        },
        'payerEmail': payment.payerEmail,
        'termsAccepted': payment.acceptedTerms,
      },
    );
    final result = data['buyCoinPack'] as Map<String, dynamic>;
    final paid = result['payment'] as Map<String, dynamic>;
    final next = result['nextAction'] as Map<String, dynamic>;
    return PackPurchase(
      paymentId: paid['id'] as String,
      coins: paid['coins'] as int? ?? 0,
      step: switch (next['type']) {
        'AWAIT_APPROVAL' => PurchaseStep.approveInNequi,
        'REDIRECT' => PurchaseStep.openBank,
        'PENDING' => PurchaseStep.wait,
        _ => PurchaseStep.done,
      },
      redirectUrl: next['redirectUrl'] as String?,
    );
  });

  CoinTransaction _movement(Map<String, dynamic> json) {
    final coins = json['coins'] as int;
    final (kind, label) = switch (json['type']) {
      'LEAD_SPEND' => (CoinTransactionKind.leadSpend, 'Contacto de proyecto'),
      'LEAD_REFUND' => (CoinTransactionKind.refund, 'Reembolso de contacto'),
      _ => (CoinTransactionKind.purchase, 'Recarga de $coins coins'),
    };
    return CoinTransaction(
      id: json['id'] as String,
      kind: kind,
      amount: coins,
      label: label,
      at: DateTime.parse(json['createdAt'] as String),
    );
  }
}
