import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

ManoConfig _config(String url) =>
    ManoConfig(gatewayGraphQlUrl: url, appRole: ManoRole.provider);

void main() {
  test('the subscription socket sits beside the GraphQL endpoint', () {
    expect(
      _config('http://localhost:8082/graphql').gatewaySubscriptionUrl,
      'ws://localhost:8082/subscription',
    );
  });

  test('a secure gateway gets a secure socket', () {
    expect(
      _config('https://api.mano.co/graphql').gatewaySubscriptionUrl,
      'wss://api.mano.co/subscription',
    );
  });

  test('keeps the role this app signs people up as', () {
    expect(_config('http://gw/graphql').appRole, ManoRole.provider);
  });
}
