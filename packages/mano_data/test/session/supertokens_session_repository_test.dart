import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

final _api = Uri.parse('http://auth.test');
final _expiry = DateTime.utc(2026, 10, 12, 10);

String frontToken({
  String uid = 'user-1',
  List<String> roles = const ['requester'],
}) => base64.encode(
  utf8.encode(
    jsonEncode({
      'uid': uid,
      'ate': _expiry.millisecondsSinceEpoch,
      'up': {
        'st-role': {'v': roles, 't': 0},
      },
    }),
  ),
);

Map<String, String> tokenHeaders({
  String access = 'access-1',
  String refresh = 'refresh-1',
}) => {
  'st-access-token': access,
  'st-refresh-token': refresh,
  'front-token': frontToken(),
};

http.Response ok(
  Map<String, Object?> body, {
  Map<String, String> headers = const {},
}) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json', ...headers},
);

void main() {
  late List<http.Request> sent;
  late InMemoryTokenStore store;

  SuperTokensSessionRepository repositoryWith(
    Future<http.Response> Function(http.Request) handler,
  ) {
    sent = [];
    store = InMemoryTokenStore();
    return SuperTokensSessionRepository(
      apiDomain: _api,
      tokens: store,
      httpClient: MockClient((request) {
        sent.add(request);
        return handler(request);
      }),
    );
  }

  final credentials = Credentials(email: 'ana@mano.co', password: 'secret');

  group('signIn', () {
    test('posts email-password form fields in header mode', () async {
      final repository = repositoryWith(
        (_) async => ok({
          'status': 'OK',
          'user': {'id': 'user-1'},
        }, headers: tokenHeaders()),
      );

      await repository.signIn(credentials);

      final request = sent.single;
      expect(request.method, 'POST');
      expect(request.url, Uri.parse('http://auth.test/auth/signin'));
      expect(request.headers['st-auth-mode'], 'header');
      expect(request.headers['rid'], 'emailpassword');
      expect(jsonDecode(request.body), {
        'formFields': [
          {'id': 'email', 'value': 'ana@mano.co'},
          {'id': 'password', 'value': 'secret'},
        ],
      });
    });

    test(
      'builds the session from the token headers and keeps the refresh token',
      () async {
        final repository = repositoryWith(
          (_) async => ok({
            'status': 'OK',
            'user': {'id': 'user-1'},
          }, headers: tokenHeaders()),
        );

        final result = await repository.signIn(credentials);

        final session = (result as Ok<Session, AuthFailure>).value;
        expect(session.accessToken, 'access-1');
        expect(session.expiresAt, _expiry);
        expect(session.user.subject, 'user-1');
        expect(session.user.email, 'ana@mano.co');
        expect(session.user.roles, {ManoRole.requester});
        expect(await store.read(), 'refresh-1');
      },
    );

    test('wrong credentials are WrongCredentials, not unavailable', () async {
      final repository = repositoryWith(
        (_) async => ok({'status': 'WRONG_CREDENTIALS_ERROR'}),
      );

      final result = await repository.signIn(credentials);

      expect((result as Err).failure, isA<WrongCredentials>());
      expect(await store.read(), isNull);
    });

    test('a server error is unavailable', () async {
      final repository = repositoryWith(
        (_) async => http.Response('boom', 500),
      );

      expect(
        (await repository.signIn(credentials) as Err).failure,
        isA<AuthUnavailable>(),
      );
    });

    test('an unreachable server is unavailable', () async {
      final repository = repositoryWith(
        (_) async => throw http.ClientException('offline'),
      );

      expect(
        (await repository.signIn(credentials) as Err).failure,
        isA<AuthUnavailable>(),
      );
    });
  });

  group('signUp', () {
    test('posts to the signup route and signs the new account in', () async {
      final repository = repositoryWith(
        (_) async => ok({
          'status': 'OK',
          'user': {'id': 'user-1'},
        }, headers: tokenHeaders()),
      );

      final result = await repository.signUp(
        credentials,
        role: ManoRole.requester,
      );

      expect(sent.single.url.path, '/auth/signup');
      expect(result, isA<Ok<Session, AuthFailure>>());
    });

    test('sends the role as a form field beside email and password', () async {
      final repository = repositoryWith(
        (_) async => ok({
          'status': 'OK',
          'user': {'id': 'user-1'},
        }, headers: tokenHeaders()),
      );

      await repository.signUp(credentials, role: ManoRole.provider);

      final request = sent.single;
      expect(request.headers['rid'], 'emailpassword');
      expect(request.headers['st-auth-mode'], 'header');
      expect(jsonDecode(request.body), {
        'formFields': [
          {'id': 'email', 'value': 'ana@mano.co'},
          {'id': 'password', 'value': 'secret'},
          {'id': 'role', 'value': 'provider'},
        ],
      });
    });

    test('another field error stays rejected, with the reason', () async {
      final repository = repositoryWith(
        (_) async => ok({
          'status': 'FIELD_ERROR',
          'formFields': [
            {'id': 'password', 'error': 'Password must contain a number'},
          ],
        }),
      );

      final failure =
          (await repository.signUp(credentials, role: ManoRole.provider)
                  as Err)
              .failure;

      expect(failure, isA<SignInRejected>());
      expect((failure as SignInRejected).reason, contains('password'));
    });

    test('a server error during sign-up is unavailable', () async {
      final repository = repositoryWith(
        (_) async => http.Response('boom', 502),
      );

      expect(
        (await repository.signUp(credentials, role: ManoRole.provider) as Err)
            .failure,
        isA<AuthUnavailable>(),
      );
    });

    test('an unreachable server during sign-up is unavailable', () async {
      final repository = repositoryWith(
        (_) async => throw http.ClientException('offline'),
      );

      expect(
        (await repository.signUp(credentials, role: ManoRole.provider) as Err)
            .failure,
        isA<AuthUnavailable>(),
      );
    });

    test(
      'a taken email is EmailAlreadyRegistered',
      () async {
        final repository = repositoryWith(
          (_) async => ok({
            'status': 'FIELD_ERROR',
            'formFields': [
              {
                'id': 'email',
                'error': 'This email already exists. Please sign in instead.',
              },
            ],
          }),
        );

        final failure =
            (await repository.signUp(credentials, role: ManoRole.requester)
                    as Err)
                .failure;

        expect(failure, isA<EmailAlreadyRegistered>());
      },
    );
  });

  group('refresh and restore', () {
    test('restore with nothing stored is nobody signed in', () async {
      final repository = repositoryWith(
        (_) async => fail('no request expected'),
      );

      expect(await repository.restore(), const Ok<Session?, AuthFailure>(null));
    });

    test('restore exchanges the stored refresh token and rotates it', () async {
      final repository = repositoryWith(
        (_) async => ok(
          {},
          headers: tokenHeaders(access: 'access-2', refresh: 'refresh-2'),
        ),
      );
      await store.write('refresh-1');

      final result = await repository.restore();

      final request = sent.single;
      expect(request.url.path, '/auth/session/refresh');
      expect(request.headers['authorization'], 'Bearer refresh-1');
      expect((result as Ok).value?.accessToken, 'access-2');
      expect(await store.read(), 'refresh-2');
    });

    test('a refused refresh token is expired and forgotten', () async {
      final repository = repositoryWith((_) async => http.Response('', 401));
      await store.write('refresh-1');

      expect(
        (await repository.refresh() as Err).failure,
        isA<SessionExpired>(),
      );
      expect(await store.read(), isNull);
    });

    test('an offline refresh keeps the token for later', () async {
      final repository = repositoryWith(
        (_) async => throw http.ClientException('offline'),
      );
      await store.write('refresh-1');

      expect(
        (await repository.restore() as Err).failure,
        isA<AuthUnavailable>(),
      );
      expect(await store.read(), 'refresh-1');
    });
  });

  group('signOut', () {
    test(
      'revokes with the access token and forgets the refresh token',
      () async {
        final repository = repositoryWith(
          (request) async => request.url.path == '/auth/signin'
              ? ok({
                  'status': 'OK',
                  'user': {'id': 'user-1'},
                }, headers: tokenHeaders())
              : ok({'status': 'OK'}),
        );
        await repository.signIn(credentials);

        await repository.signOut();

        expect(sent.last.url.path, '/auth/signout');
        expect(sent.last.headers['authorization'], 'Bearer access-1');
        expect(await store.read(), isNull);
      },
    );

    test('still forgets locally when the server cannot be reached', () async {
      final repository = repositoryWith(
        (_) async => throw http.ClientException('offline'),
      );
      await store.write('refresh-1');

      await repository.signOut();

      expect(await store.read(), isNull);
    });
  });
}
