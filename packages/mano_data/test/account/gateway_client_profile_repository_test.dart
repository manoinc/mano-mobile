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

const _seed = ClientProfile(displayName: 'Ana', email: 'ana@mano.co');

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

const _served = {
  'displayName': 'Ana Rojas',
  'photoUrl': 'https://media/ana.jpg',
  'phone': '3001234567',
  'email': 'ana.rojas@mano.co',
};

GatewayClientProfileRepository _repo(MockClientHandler handler) =>
    GatewayClientProfileRepository(
      GatewayTransport(_config, httpClient: MockClient(handler)),
      seed: _seed,
    );

void main() {
  test('profile reads viewer.clientProfile', () async {
    final repo = _repo((r) async {
      expect(_body(r)['query'], contains('clientProfile'));
      return _data({
        'viewer': {'clientProfile': _served},
      });
    });

    expect(
      await repo.profile(),
      const ClientProfile(
        displayName: 'Ana Rojas',
        phone: '3001234567',
        email: 'ana.rojas@mano.co',
        photoUrl: 'https://media/ana.jpg',
      ),
    );
  });

  test('a fresh account reads as the seed without writing anything', () async {
    var calls = 0;
    final repo = _repo((r) async {
      calls++;
      expect(_body(r)['query'], isNot(contains('updateClientProfile')));
      return _data({
        'viewer': {'clientProfile': null},
      });
    });

    expect(await repo.profile(), _seed);
    expect(calls, 1);
  });

  test('blank served fields fall back to the seed', () async {
    final repo = _repo(
      (_) async => _data({
        'viewer': {
          'clientProfile': {
            'displayName': '',
            'photoUrl': null,
            'phone': null,
            'email': null,
          },
        },
      }),
    );

    expect(await repo.profile(), _seed);
  });

  test('update sends name, phone and email and maps the answer', () async {
    final repo = _repo((r) async {
      final body = _body(r);
      expect(body['query'], contains('updateClientProfile'));
      expect(body['variables'], {
        'input': {
          'displayName': 'Ana Rojas',
          'phone': '3001234567',
          'email': 'ana.rojas@mano.co',
        },
      });
      return _data({'updateClientProfile': _served});
    });

    final result = await repo.update(
      const ClientProfile(
        displayName: 'Ana Rojas',
        phone: '3001234567',
        email: 'ana.rojas@mano.co',
      ),
    );

    expect(result.valueOrNull?.photoUrl, 'https://media/ana.jpg');
  });

  test('update refuses a profile with problems before calling', () async {
    final repo = _repo((_) async => fail('must not call the gateway'));

    final result = await repo.update(const ClientProfile());

    expect(result.failureOrNull, isA<DataRejected>());
  });

  test('updatePhoto sends the media id, never the url', () async {
    final repo = _repo((r) async {
      expect(_body(r)['variables'], {
        'input': {'photoMediaId': 'media-1'},
      });
      return _data({'updateClientProfile': _served});
    });

    final result = await repo.updatePhoto(
      const MediaAttachment(id: 'media-1', url: 'https://signed/tmp'),
    );

    expect(result.valueOrNull?.photoUrl, 'https://media/ana.jpg');
  });

  test('a refusal is a DataFailure', () async {
    final repo = _repo((_) async => _error('InvalidArgument: bad phone'));

    final result = await repo.update(
      const ClientProfile(
        displayName: 'Ana Rojas',
        phone: '3001234567',
        email: 'ana@mano.co',
      ),
    );

    expect(result.failureOrNull, isA<DataRejected>());
  });
}
