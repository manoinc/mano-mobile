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

  test('invite links default to manoapp.co/r/<code>', () {
    expect(
      _config('http://gw/graphql').inviteLink('RP-bb2cde6b').toString(),
      'https://manoapp.co/r/RP-bb2cde6b',
    );
  });

  test('the invite link base can be replaced and the code is escaped', () {
    const config = ManoConfig(
      gatewayGraphQlUrl: 'http://gw/graphql',
      appRole: ManoRole.provider,
      inviteLinkBase: 'https://staging.manoapp.co/r/',
    );
    expect(
      config.inviteLink('A B').toString(),
      'https://staging.manoapp.co/r/A%20B',
    );
  });

  test('keeps the role this app signs people up as', () {
    expect(_config('http://gw/graphql').appRole, ManoRole.provider);
  });

  test('Google sign-in is off until a server client ID is given', () {
    expect(_config('http://gw/graphql').googleServerClientId, isNull);
    expect(
      const ManoConfig(
        gatewayGraphQlUrl: 'http://gw/graphql',
        appRole: ManoRole.provider,
        googleServerClientId: 'web.apps.googleusercontent.com',
      ).googleServerClientId,
      'web.apps.googleusercontent.com',
    );
  });
}
