import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

const _config = ManoConfig(
  gatewayGraphQlUrl: 'http://gw/graphql',
  appRole: ManoRole.requester,
);

GatewayReferralLinker _linker(MockClientHandler handler) =>
    GatewayReferralLinker(
      GatewayTransport(_config, httpClient: MockClient(handler)),
    );

http.Response _json(Object body) => http.Response(jsonEncode(body), 200);

void main() {
  test('links the trimmed code as typed and returns the name', () async {
    final linker = _linker((r) async {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      expect(body['query'], contains('linkWorkerByReferralCode'));
      expect(body['variables'], {'code': 'RP-1a2b3c4d'});
      return _json({
        'data': {
          'linkWorkerByReferralCode': {'displayName': 'Carlos Mendoza'},
        },
      });
    });

    expect((await linker.link(' RP-1a2b3c4d ')).valueOrNull, 'Carlos Mendoza');
  });

  test('an unknown code is not found', () async {
    final linker = _linker(
      (_) async => _json({
        'errors': [
          {'message': 'NotFound: no worker has that referral code'},
        ],
      }),
    );

    expect((await linker.link('NOPE')).failureOrNull, isA<DataNotFound>());
  });

  test('a blank code is refused without calling', () async {
    final linker = _linker((_) async => fail('must not call the gateway'));

    expect((await linker.link('  ')).failureOrNull, isA<DataRejected>());
  });
}
