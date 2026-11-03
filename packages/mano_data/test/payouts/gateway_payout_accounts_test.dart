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

Map<String, dynamic> _body(http.Request r) =>
    jsonDecode(r.body) as Map<String, dynamic>;

GatewayPayoutAccounts _accounts(MockClientHandler handler) =>
    GatewayPayoutAccounts(
      GatewayTransport(_config, httpClient: MockClient(handler)),
    );

const _holder = AccountHolder(
  name: 'Andrés Castro',
  email: 'andres@mano.test',
  legalIdType: LegalIdType.cc,
  legalId: '1020304050',
);

Map<String, Object?> _registered(String type, {String? bankCode}) => {
  'registerPayoutAccount': {
    'id': 'acc-1',
    'type': type,
    'bankCode': bankCode,
    'last4': '5678',
    'createdAt': '2026-11-02T15:00:00Z',
  },
};

void main() {
  test('a bank account is registered with its holder', () async {
    final accounts = _accounts((r) async {
      expect(_body(r)['query'], contains('registerPayoutAccount(input:'));
      expect(_body(r)['variables'], {
        'input': {
          'bank': {
            'bankCode': '1007',
            'accountType': 'CHECKING',
            'accountNumber': '12345678',
          },
          'holder': {
            'name': 'Andrés Castro',
            'email': 'andres@mano.test',
            'legalIdType': 'CC',
            'legalId': '1020304050',
          },
        },
      });
      return _data(_registered('BANK_ACCOUNT', bankCode: '1007'));
    });
    const bank = BankDestination(
      bankCode: '1007',
      accountType: BankAccountType.checking,
      accountNumber: '12345678',
    );

    final account = (await accounts.register(
      destination: bank,
      holder: _holder,
    )).valueOrNull!;

    expect(account.id, 'acc-1');
    expect(account.destination, bank);
    expect((await accounts.current()).valueOrNull?.id, 'acc-1');
  });

  test('a Nequi account sends the wallet phone', () async {
    final accounts = _accounts((r) async {
      expect(_body(r)['variables']['input']['wallet'], {'phone': '3001234567'});
      return _data(_registered('DIGITAL_WALLET'));
    });
    final result = await accounts.register(
      destination: const NequiDestination(phone: '3001234567'),
      holder: _holder,
    );
    expect(result.isOk, isTrue);
  });

  test('nothing is registered until this session registers one', () async {
    final accounts = _accounts((r) async => fail('no read query exists'));
    expect((await accounts.current()).valueOrNull, isNull);
  });

  test('removing is refused: billing has no such call', () async {
    final accounts = _accounts((r) async => fail('must not be sent'));
    expect((await accounts.remove('acc-1')).failureOrNull, isA<DataRejected>());
  });

  test('payout banks come from the gateway', () async {
    final accounts = _accounts((r) async {
      expect(_body(r)['query'], contains('payoutBanks'));
      return _data({
        'payoutBanks': [
          {'code': '1007', 'name': 'Bancolombia'},
        ],
      });
    });
    expect((await accounts.banks()).valueOrNull, const [
      Bank(code: '1007', name: 'Bancolombia'),
    ]);
  });
}
