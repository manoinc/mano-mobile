import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mano_data/mano_data.dart';
import 'package:test/test.dart';

const _config = ManoConfig(gatewayGraphQlUrl: 'http://gw/graphql');

GatewayTransport _transport(MockClientHandler handler) =>
    GatewayTransport(_config, httpClient: MockClient(handler));

void main() {
  test('posts the document and variables and returns data', () async {
    late Map<String, dynamic> sent;
    final transport = _transport((request) async {
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      expect(request.headers['Authorization'], isNull);
      return http.Response(
        jsonEncode({
          'data': {'ok': true},
        }),
        200,
      );
    });

    final data = await transport.run('{ ok }', variables: {'a': 1});

    expect(data, {'ok': true});
    expect(sent['query'], '{ ok }');
    expect(sent['variables'], {'a': 1});
  });

  test('sends a bearer token when given one', () async {
    final transport = _transport((request) async {
      expect(request.headers['Authorization'], 'Bearer t0k');
      return http.Response(jsonEncode({'data': {}}), 200);
    });

    await transport.run('{ ok }', accessToken: 't0k');
  });

  test('401 is unauthorized', () {
    final transport = _transport((_) async => http.Response('', 401));
    expect(transport.run('{ ok }'), throwsA(isA<GatewayUnauthorized>()));
  });

  test('5xx is unavailable', () {
    final transport = _transport((_) async => http.Response('', 503));
    expect(transport.run('{ ok }'), throwsA(isA<GatewayUnavailable>()));
  });

  test('a network failure is unavailable', () {
    final transport = _transport((_) async => throw http.ClientException('x'));
    expect(transport.run('{ ok }'), throwsA(isA<GatewayUnavailable>()));
  });

  test('GraphQL errors are rejections carrying the first message', () {
    final transport = _transport(
      (_) async => http.Response(
        jsonEncode({
          'errors': [
            {'message': 'not found'},
          ],
        }),
        200,
      ),
    );
    expect(
      transport.run('{ ok }'),
      throwsA(
        isA<GatewayRejected>().having((e) => e.message, 'message', 'not found'),
      ),
    );
  });
}
