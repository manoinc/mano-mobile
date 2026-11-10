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

final _code = ReferralCode.parse('RP-1a2b3c4d')!;

GatewayWorkerReferralRedeemer _redeemer(MockClientHandler handler) =>
    GatewayWorkerReferralRedeemer(
      GatewayTransport(_config, httpClient: MockClient(handler)),
    );

http.Response _json(Object body) => http.Response(jsonEncode(body), 200);

http.Response _error(String code) => _json({
  'errors': [
    {
      'message': 'refused',
      'extensions': {'code': code},
    },
  ],
});

void main() {
  test('redeems the code through redeemWorkerReferral', () async {
    final redeemer = _redeemer((r) async {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      expect(body['query'], contains('redeemWorkerReferral(code: \$code)'));
      expect(body['variables'], {'code': 'RP-1a2b3c4d'});
      return _json({
        'data': {
          'redeemWorkerReferral': {'id': 'w1'},
        },
      });
    });

    expect((await redeemer.redeem(_code)).isOk, isTrue);
  });

  test('each extensions.code becomes its failure', () async {
    const cases = {
      'REFERRAL_NOT_FOUND': ReferralRedemptionFailure.unknownCode,
      'REFERRAL_SELF': ReferralRedemptionFailure.ownCode,
      'REFERRAL_ALREADY_REDEEMED': ReferralRedemptionFailure.alreadyRedeemed,
      'INTERNAL': ReferralRedemptionFailure.notSaved,
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      final result = await _redeemer((_) async => _error(key)).redeem(_code);
      expect(result.failureOrNull, value, reason: key);
    }
  });

  test('an outage is not saved', () async {
    final redeemer = _redeemer((_) async => http.Response('', 503));

    expect(
      (await redeemer.redeem(_code)).failureOrNull,
      ReferralRedemptionFailure.notSaved,
    );
  });
}
