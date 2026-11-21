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

  group('fromEnv', () {
    const env = {
      'MANO_GATEWAY': 'http://localhost:8082/graphql',
      'SUPERTOKENS_API_DOMAIN': 'http://localhost:3001',
      'GOOGLE_SERVER_CLIENT_ID': 'web.apps.googleusercontent.com',
      'MANO_INVITE_LINK_BASE': 'https://staging.manoapp.co/r/',
      'MANO_APPROVE_IDENTITY': 'true',
      'SENTRY_DSN': 'https://key@o1.ingest.us.sentry.io/2',
      'SENTRY_ENVIRONMENT': 'production',
    };

    test('reads every service from the .env values', () {
      final config = ManoConfig.fromEnv(env, appRole: ManoRole.requester);
      expect(config.gatewayGraphQlUrl, 'http://localhost:8082/graphql');
      expect(config.authApiDomain, 'http://localhost:3001');
      expect(config.googleServerClientId, 'web.apps.googleusercontent.com');
      expect(config.inviteLinkBase, 'https://staging.manoapp.co/r/');
      expect(config.approveIdentityChecks, isTrue);
      expect(config.appRole, ManoRole.requester);
      expect(config.sentryDsn, 'https://key@o1.ingest.us.sentry.io/2');
      expect(config.sentryEnvironment, 'production');
    });

    test('blank optional keys stay off', () {
      final config = ManoConfig.fromEnv(const {
        'MANO_GATEWAY': 'http://gw/graphql',
        'SUPERTOKENS_API_DOMAIN': '',
        'GOOGLE_SERVER_CLIENT_ID': '',
        'SENTRY_DSN': '',
        'SENTRY_ENVIRONMENT': '',
      }, appRole: ManoRole.provider);
      expect(config.authApiDomain, isNull);
      expect(config.googleServerClientId, isNull);
      expect(config.approveIdentityChecks, isFalse);
      expect(config.inviteLink('X').toString(), 'https://manoapp.co/r/X');
      expect(config.sentryDsn, isNull);
      expect(config.sentryEnvironment, 'development');
    });

    test('a missing gateway fails loudly, naming the config files', () {
      expect(
        () => ManoConfig.fromEnv(const {}, appRole: ManoRole.provider),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('MANO_GATEWAY'),
              contains('config/dev.json'),
              contains('.env'),
            ),
          ),
        ),
      );
    });

    test('a blank gateway counts as missing', () {
      expect(
        () => ManoConfig.fromEnv(const {
          'MANO_GATEWAY': '   ',
        }, appRole: ManoRole.provider),
        throwsStateError,
      );
    });
  });
}
