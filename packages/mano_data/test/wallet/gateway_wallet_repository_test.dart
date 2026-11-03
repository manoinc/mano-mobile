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

http.Response _data(Object data) =>
    http.Response(jsonEncode({'data': data}), 200);

http.Response _error(String message) => http.Response(
  jsonEncode({
    'errors': [
      {'message': message},
    ],
  }),
  200,
);

Map<String, dynamic> _body(http.Request r) =>
    jsonDecode(r.body) as Map<String, dynamic>;

GatewayWalletRepository _repo(MockClientHandler handler) =>
    GatewayWalletRepository(
      GatewayTransport(_config, httpClient: MockClient(handler)),
    );

const _nequi = CoinPurchaseDraft(
  packId: 'pack-1',
  method: CoinPurchaseMethod.nequi,
  phone: '300 123 4567',
  payerEmail: 'andres@mano.test',
  termsAccepted: true,
);

Map<String, Object?> _result({
  String status = 'PENDING',
  String next = 'AWAIT_APPROVAL',
  String? url,
  String? reason,
}) => {
  'buyCoinPack': {
    'payment': {
      'id': 'pay-1',
      'status': status,
      'coins': 28,
      'failureReason': reason,
    },
    'nextAction': {'type': next, 'redirectUrl': url},
  },
};

void main() {
  test('wallet reads myCoinWallet', () async {
    final repo = _repo((r) async {
      expect(_body(r)['query'], contains('myCoinWallet'));
      return _data({
        'myCoinWallet': {'balance': 12},
      });
    });
    expect(await repo.wallet(), const Wallet(balance: 12));
  });

  test('packs map coins, bonus and the price in whole pesos', () async {
    final repo = _repo(
      (r) async => _data({
        'coinPacks': [
          {
            'id': 'pack-1',
            'coins': 25,
            'bonus': 3,
            'price': {'amount': 45000.0, 'currency': 'COP'},
          },
        ],
      }),
    );
    expect(await repo.packs(), const [
      CoinPack(id: 'pack-1', coins: 25, priceCop: 45000, bonus: 3),
    ]);
  });

  test('history maps purchases newest first as credits', () async {
    final repo = _repo((r) async {
      expect(_body(r)['query'], contains('myCoinMovements'));
      return _data({
        'myCoinMovements': {
          'items': [
            {
              'id': 'm1',
              'type': 'PURCHASE',
              'coins': 28,
              'paymentId': 'pay-1',
              'createdAt': '2026-11-02T15:00:00Z',
            },
          ],
          'pageInfo': {'hasNextPage': false, 'nextCursor': null},
        },
      });
    });
    final history = await repo.history();
    expect(history.single.kind, CoinTransactionKind.purchase);
    expect(history.single.amount, 28);
    expect(history.single.label, 'Recarga de 28 coins');
    expect(history.single.at, DateTime.utc(2026, 11, 2, 15).toLocal());
  });

  test('history maps lead spends and refunds and asks for the lead', () async {
    final repo = _repo((r) async {
      expect(_body(r)['query'], contains('leadId'));
      return _data({
        'myCoinMovements': {
          'items': [
            {
              'id': 'm2',
              'type': 'LEAD_REFUND',
              'coins': 3,
              'leadId': 'lead-1',
              'createdAt': '2026-11-03T15:00:00Z',
            },
            {
              'id': 'm1',
              'type': 'LEAD_SPEND',
              'coins': -3,
              'leadId': 'lead-1',
              'createdAt': '2026-11-02T15:00:00Z',
            },
          ],
          'pageInfo': {'hasNextPage': false, 'nextCursor': null},
        },
      });
    });
    final history = await repo.history();
    expect(history.first.kind, CoinTransactionKind.refund);
    expect(history.first.label, 'Reembolso de contacto');
    expect(history.first.amount, 3);
    expect(history.last.kind, CoinTransactionKind.leadSpend);
    expect(history.last.label, 'Contacto de proyecto');
    expect(history.last.amount, -3);
  });

  test(
    'a Nequi purchase sends the wallet method and awaits approval',
    () async {
      final repo = _repo((r) async {
        expect(_body(r)['query'], contains('buyCoinPack('));
        expect(_body(r)['variables'], {
          'packId': 'pack-1',
          'method': {
            'wallet': {'phone': '3001234567'},
          },
          'payerEmail': 'andres@mano.test',
          'termsAccepted': true,
        });
        return _data(_result());
      });
      final purchase = (await repo.buyPack(_nequi)).valueOrNull;
      expect(purchase, isA<AwaitingApproval>());
      expect(purchase!.paymentId, 'pay-1');
      expect(purchase.coins, 28);
    },
  );

  test('a PSE purchase sends the bank and payer, and redirects', () async {
    final repo = _repo((r) async {
      expect(_body(r)['variables']['method'], {
        'pse': {
          'institutionCode': '1022',
          'personType': 'JURIDICAL',
          'legalIdType': 'NIT',
          'legalId': '9001234567',
        },
      });
      return _data(_result(next: 'REDIRECT', url: 'https://bank.test/pay'));
    });
    final purchase = await repo.buyPack(
      _nequi.copyWith(
        method: CoinPurchaseMethod.pse,
        bankCode: '1022',
        personType: PsePersonType.juridical,
        legalIdType: LegalIdType.nit,
        legalId: '900.123.456-7',
      ),
    );
    expect(
      (purchase.valueOrNull! as BankRedirect).url,
      'https://bank.test/pay',
    );
  });

  test('PENDING, or a redirect with no URL yet, is pending', () async {
    for (final reply in [
      _result(next: 'PENDING'),
      _result(next: 'REDIRECT'),
      _result(next: 'NONE'),
    ]) {
      final repo = _repo((r) async => _data(reply));
      expect((await repo.buyPack(_nequi)).valueOrNull, isA<PurchasePending>());
    }
  });

  test('NONE on a completed payment is completed', () async {
    final repo = _repo(
      (r) async => _data(_result(status: 'COMPLETED', next: 'NONE')),
    );
    expect((await repo.buyPack(_nequi)).valueOrNull, isA<PurchaseCompleted>());
  });

  test('a failed payment is a rejection carrying its reason', () async {
    final repo = _repo(
      (r) async => _data(
        _result(status: 'FAILED', next: 'NONE', reason: 'insufficient funds'),
      ),
    );
    expect(
      (await repo.buyPack(_nequi)).failureOrNull,
      isA<DataRejected>().having(
        (f) => f.reason,
        'reason',
        'insufficient funds',
      ),
    );
  });

  test('an invalid draft never reaches the gateway', () async {
    final repo = _repo((r) async => fail('must not be sent'));
    expect(
      (await repo.buyPack(_nequi.copyWith(termsAccepted: false))).failureOrNull,
      isA<DataRejected>(),
    );
  });

  test('a billing refusal arrives as a rejection', () async {
    final repo = _repo(
      (r) async => _error('FailedPrecondition: the terms must be accepted'),
    );
    expect((await repo.buyPack(_nequi)).failureOrNull, isA<DataRejected>());
  });

  test('checkout terms and PSE banks', () async {
    final repo = _repo((r) async {
      final query = _body(r)['query'] as String;
      if (query.contains('checkoutTerms')) {
        return _data({
          'checkoutTerms': [
            {'label': 'Términos', 'url': 'https://terms.test'},
          ],
        });
      }
      return _data({
        'pseBanks': [
          {'code': '1022', 'name': 'Banco Union'},
        ],
      });
    });
    expect((await repo.checkoutTerms()).valueOrNull, const [
      CheckoutTerm(label: 'Términos', url: 'https://terms.test'),
    ]);
    expect((await repo.pseBanks()).valueOrNull, const [
      Bank(code: '1022', name: 'Banco Union'),
    ]);
  });

  test('billing being down is unavailable', () async {
    final repo = _repo((r) async => _error('Unavailable: billing is down'));
    expect((await repo.pseBanks()).failureOrNull, isA<DataUnavailable>());
  });
}
