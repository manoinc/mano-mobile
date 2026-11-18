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

GatewayRegistrationRepository _repository(MockClientHandler handler) =>
    GatewayRegistrationRepository(
      GatewayTransport(_config, httpClient: MockClient(handler)),
    );

http.Response _json(Object body) => http.Response(jsonEncode(body), 200);

const _draft = RegistrationDraft(givenName: ' Roy ', familyName: 'Sandoval ');

void main() {
  test('saves only the full name on the client profile', () async {
    final repository = _repository((r) async {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      expect(body['query'], contains('updateClientProfile'));
      expect(body['variables'], {
        'input': {'displayName': 'Roy Sandoval'},
      });
      return _json({
        'data': {
          'updateClientProfile': {'displayName': 'Roy Sandoval'},
        },
      });
    });

    expect((await repository.submit(_draft)).isOk, isTrue);
  });

  test('a refused name is a rejection', () async {
    final repository = _repository(
      (_) async => _json({
        'errors': [
          {'message': 'InvalidArgument: displayName is too long'},
        ],
      }),
    );

    expect(
      (await repository.submit(_draft)).failureOrNull,
      isA<RegistrationRejected>(),
    );
  });

  test('an unreachable gateway is unavailable', () async {
    final repository = _repository(
      (_) async => http.Response('down', 503),
    );

    expect(
      (await repository.submit(_draft)).failureOrNull,
      isA<RegistrationUnavailable>(),
    );
  });
}
