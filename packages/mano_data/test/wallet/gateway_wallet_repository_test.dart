import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

const _config = ManoConfig(
  gatewayGraphQlUrl: 'http://gw/graphql',
  appRole: ManoRole.provider,
);

GatewayWalletRepository _wallet(MockClientHandler handler) =>
    GatewayWalletRepository(
      GatewayTransport(_config, httpClient: MockClient(handler)),
    );

Map<String, dynamic> _body(http.Request r) =>
    jsonDecode(r.body) as Map<String, dynamic>;

http.Response _data(Object data) =>
    http.Response(jsonEncode({'data': data}), 200);

void main() {
  test('reads the balance', () async {
    final wallet = _wallet(
      (_) async => _data({
        'myCoinWallet': {'balance': 28},
      }),
    );
    expect(await wallet.wallet(), const Wallet(balance: 28));
  });

  test('maps purchases, lead spends and refunds onto the history', () async {
    final wallet = _wallet(
      (_) async => _data({
        'myCoinMovements': {
          'items': [
            {
              'id': 'm3',
              'type': 'LEAD_REFUND',
              'coins': 3,
              'createdAt': '2026-11-03T12:00:00Z',
            },
            {
              'id': 'm2',
              'type': 'LEAD_SPEND',
              'coins': -3,
              'createdAt': '2026-11-03T11:00:00Z',
            },
            {
              'id': 'm1',
              'type': 'PURCHASE',
              'coins': 28,
              'createdAt': '2026-11-03T10:00:00Z',
            },
          ],
        },
      }),
    );
    final history = await wallet.history();
    expect(history.map((t) => t.kind), [
      CoinTransactionKind.refund,
      CoinTransactionKind.leadSpend,
      CoinTransactionKind.purchase,
    ]);
    expect(history.map((t) => t.amount), [3, -3, 28]);
    expect(history.last.at, DateTime.utc(2026, 11, 3, 10));
  });

  test('reads the packs in whole pesos', () async {
    final wallet = _wallet(
      (_) async => _data({
        'coinPacks': [
          {
            'id': 'p1',
            'coins': 25,
            'bonus': 3,
            'price': {'amount': 45000.0},
          },
        ],
      }),
    );
    expect(await wallet.packs(), const [
      CoinPack(id: 'p1', coins: 25, priceCop: 45000, bonus: 3),
    ]);
  });

  test('buys a pack with Nequi and says to approve it there', () async {
    late Map<String, dynamic> sent;
    final wallet = _wallet((request) async {
      sent = _body(request);
      return _data({
        'buyCoinPack': {
          'payment': {'id': 'pay-1', 'coins': 28},
          'nextAction': {'type': 'AWAIT_APPROVAL', 'redirectUrl': null},
        },
      });
    });
    final result = await wallet.buyPack(
      'p1',
      const NequiPayment(
        phone: '3001234567',
        payerEmail: 'ana@example.co',
        acceptedTerms: true,
      ),
    );
    expect(
      result.valueOrNull,
      const PackPurchase(
        paymentId: 'pay-1',
        coins: 28,
        step: PurchaseStep.approveInNequi,
      ),
    );
    final variables = sent['variables'] as Map<String, dynamic>;
    expect(variables['packId'], 'p1');
    expect(variables['method'], {
      'wallet': {'phone': '3001234567'},
    });
    expect(variables['termsAccepted'], true);
  });

  test('a refused purchase is a failure, not an exception', () async {
    final wallet = _wallet(
      (_) async => http.Response(
        jsonEncode({
          'errors': [
            {'message': 'FailedPrecondition: the payer must accept the terms'},
          ],
        }),
        200,
      ),
    );
    final result = await wallet.buyPack(
      'p1',
      const NequiPayment(
        phone: '3001234567',
        payerEmail: 'ana@example.co',
        acceptedTerms: false,
      ),
    );
    expect(result.failureOrNull, isA<DataRejected>());
  });
}
