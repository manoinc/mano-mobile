import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

/// Every collaborator of [OidcSessionRepository] is an interface, so the whole
/// class can be driven from here: no browser, no keystore, no network, no
/// device. That is the payoff of injecting interfaces rather than reaching for
/// concrete plugins.

final class _FakeOidcClient implements OidcClient {
  _FakeOidcClient({this.onAuthorize, this.onRefresh});

  final Future<OidcTokens> Function()? onAuthorize;
  final Future<OidcTokens> Function(String refreshToken)? onRefresh;

  int authorizeCalls = 0;
  int refreshCalls = 0;

  @override
  Future<OidcTokens> authorize() {
    authorizeCalls++;
    return onAuthorize?.call() ?? (throw StateError('authorize not stubbed'));
  }

  @override
  Future<OidcTokens> refresh(String refreshToken) {
    refreshCalls++;
    return onRefresh?.call(refreshToken) ??
        (throw StateError('refresh not stubbed'));
  }
}

final class _FakeGatewayClient implements GatewayClient {
  _FakeGatewayClient({this.onMe});

  final Future<AuthenticatedUser> Function(String accessToken)? onMe;

  String? lastToken;

  @override
  Future<AuthenticatedUser> me(String accessToken) {
    lastToken = accessToken;
    return onMe?.call(accessToken) ?? (throw StateError('me not stubbed'));
  }
}

OidcTokens tokens({String refreshToken = 'refresh-1'}) => OidcTokens(
  accessToken: 'access-1',
  expiresAt: DateTime.now().add(const Duration(minutes: 5)),
  refreshToken: refreshToken,
);

const user = AuthenticatedUser(
  subject: 'user-1',
  username: 'mano-test',
  roles: {ManoRole.provider},
);

void main() {
  group('signIn', () {
    test('returns a session built from what the gateway vouched for', () async {
      final store = InMemoryTokenStore();
      final repository = OidcSessionRepository(
        oidcClient: _FakeOidcClient(onAuthorize: () async => tokens()),
        gatewayClient: _FakeGatewayClient(onMe: (_) async => user),
        tokenStore: store,
      );

      final result = await repository.signIn();

      expect(result.isOk, isTrue);
      final session = result.valueOrNull!;
      expect(session.user, user);
      expect(session.accessToken, 'access-1');
      // The identity came from the gateway, not from decoding the token here.
      expect(session.user.isProvider, isTrue);
    });

    test('persists the refresh token so the next launch can restore', () async {
      final store = InMemoryTokenStore();
      final repository = OidcSessionRepository(
        oidcClient: _FakeOidcClient(onAuthorize: () async => tokens()),
        gatewayClient: _FakeGatewayClient(onMe: (_) async => user),
        tokenStore: store,
      );

      await repository.signIn();

      expect(await store.read(), 'refresh-1');
    });

    test('backing out is a cancellation, not an error', () async {
      // The interface must be able to tell "changed their mind" from "was
      // refused", or it shows an error message to someone who just pressed
      // back.
      final repository = OidcSessionRepository(
        oidcClient: _FakeOidcClient(
          onAuthorize: () async => throw const OidcCancelled(),
        ),
        gatewayClient: _FakeGatewayClient(),
        tokenStore: InMemoryTokenStore(),
      );

      final result = await repository.signIn();

      expect(result.failureOrNull, isA<SignInCancelled>());
    });

    test('an unreachable authorization server is not the user\'s fault', () async {
      final repository = OidcSessionRepository(
        oidcClient: _FakeOidcClient(
          onAuthorize: () async => throw const OidcFailed('no route to host'),
        ),
        gatewayClient: _FakeGatewayClient(),
        tokenStore: InMemoryTokenStore(),
      );

      final result = await repository.signIn();

      expect(result.failureOrNull, isA<AuthUnavailable>());
    });

    test('a token the gateway refuses is reported as a rejection', () async {
      // In practice this means a misconfiguration -- a mismatched issuer, or a
      // client with no audience mapper -- so the detail is worth keeping.
      final repository = OidcSessionRepository(
        oidcClient: _FakeOidcClient(onAuthorize: () async => tokens()),
        gatewayClient: _FakeGatewayClient(
          onMe: (_) async => throw const GatewayUnauthorized('401'),
        ),
        tokenStore: InMemoryTokenStore(),
      );

      final result = await repository.signIn();

      expect(result.failureOrNull, isA<SignInRejected>());
      expect((result.failureOrNull! as SignInRejected).reason, '401');
    });

    test('an unreachable gateway is reported as unavailable', () async {
      final repository = OidcSessionRepository(
        oidcClient: _FakeOidcClient(onAuthorize: () async => tokens()),
        gatewayClient: _FakeGatewayClient(
          onMe: (_) async => throw const GatewayUnavailable('connection refused'),
        ),
        tokenStore: InMemoryTokenStore(),
      );

      final result = await repository.signIn();

      expect(result.failureOrNull, isA<AuthUnavailable>());
    });

    test('the access token is what gets presented to the gateway', () async {
      final gateway = _FakeGatewayClient(onMe: (_) async => user);
      final repository = OidcSessionRepository(
        oidcClient: _FakeOidcClient(onAuthorize: () async => tokens()),
        gatewayClient: gateway,
        tokenStore: InMemoryTokenStore(),
      );

      await repository.signIn();

      expect(gateway.lastToken, 'access-1');
    });
  });

  group('restore', () {
    test('no stored token is an ordinary first launch, not a failure', () async {
      final repository = OidcSessionRepository(
        oidcClient: _FakeOidcClient(),
        gatewayClient: _FakeGatewayClient(),
        tokenStore: InMemoryTokenStore(),
      );

      final result = await repository.restore();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('a stored token is exchanged without troubling the user', () async {
      final oidc = _FakeOidcClient(onRefresh: (_) async => tokens());
      final repository = OidcSessionRepository(
        oidcClient: oidc,
        gatewayClient: _FakeGatewayClient(onMe: (_) async => user),
        tokenStore: InMemoryTokenStore('stored-refresh'),
      );

      final result = await repository.restore();

      expect(result.valueOrNull?.user, user);
      expect(oidc.refreshCalls, 1);
      expect(oidc.authorizeCalls, 0, reason: 'must not open a browser');
    });

    test('a revoked grant expires the session and forgets the token', () async {
      // Keeping a dead refresh token would mean retrying this on every launch.
      final store = InMemoryTokenStore('revoked');
      final repository = OidcSessionRepository(
        oidcClient: _FakeOidcClient(
          onRefresh: (_) async =>
              throw const OidcFailed('invalid_grant', recoverable: false),
        ),
        gatewayClient: _FakeGatewayClient(),
        tokenStore: store,
      );

      final result = await repository.restore();

      expect(result.failureOrNull, isA<SessionExpired>());
      expect(await store.read(), isNull);
    });

    test('a transient failure keeps the token for a later attempt', () async {
      final store = InMemoryTokenStore('still-good');
      final repository = OidcSessionRepository(
        oidcClient: _FakeOidcClient(
          onRefresh: (_) async => throw const OidcFailed('network down'),
        ),
        gatewayClient: _FakeGatewayClient(),
        tokenStore: store,
      );

      final result = await repository.restore();

      expect(result.failureOrNull, isA<AuthUnavailable>());
      expect(await store.read(), 'still-good', reason: 'still worth retrying');
    });
  });

  group('refresh', () {
    test('without a stored token the session has expired', () async {
      final repository = OidcSessionRepository(
        oidcClient: _FakeOidcClient(),
        gatewayClient: _FakeGatewayClient(),
        tokenStore: InMemoryTokenStore(),
      );

      final result = await repository.refresh();

      expect(result.failureOrNull, isA<SessionExpired>());
    });
  });

  group('signOut', () {
    test('discards the stored credential', () async {
      final store = InMemoryTokenStore('refresh-1');
      final repository = OidcSessionRepository(
        oidcClient: _FakeOidcClient(),
        gatewayClient: _FakeGatewayClient(),
        tokenStore: store,
      );

      await repository.signOut();

      expect(await store.read(), isNull);
    });
  });
}
