import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

final class _FakeSource implements IdTokenSource {
  _FakeSource(this._answer);

  final Future<String?> Function() _answer;

  @override
  Future<String?> idToken() => _answer();
}

Map<String, String> _tokenHeaders() => {
  'st-access-token': 'access-1',
  'st-refresh-token': 'refresh-1',
  'front-token': base64.encode(
    utf8.encode(
      jsonEncode({
        'uid': 'user-7',
        'ate': DateTime.utc(2026, 11, 8).millisecondsSinceEpoch,
        'up': {
          'email': 'ana@gmail.com',
          'st-role': {
            'v': ['requester'],
            't': 0,
          },
        },
      }),
    ),
  ),
};

http.Response _ok(Map<String, Object?> body, {Map<String, String>? headers}) =>
    http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json', ...?headers},
    );

void main() {
  late List<http.Request> sent;

  SupertokensSocialAuth authWith(
    Future<http.Response> Function(http.Request) handler, {
    Map<SocialProvider, IdTokenSource>? sources,
  }) {
    sent = [];
    final fdi = SuperTokensFdi(
      apiDomain: Uri.parse('http://auth.test'),
      tokens: InMemoryTokenStore(),
      httpClient: MockClient((request) {
        sent.add(request);
        return handler(request);
      }),
    );
    return SupertokensSocialAuth(
      fdi,
      sources:
          sources ??
          {
            SocialProvider.google: _FakeSource(() async => 'google-id-token'),
            SocialProvider.apple: _FakeSource(() async => 'apple-id-token'),
          },
    );
  }

  Map<String, dynamic> bodyOf(http.Request request) =>
      jsonDecode(request.body) as Map<String, dynamic>;

  test('posts the Google id token with the thirdparty rid', () async {
    final auth = authWith(
      (_) async => _ok({
        'status': 'OK',
        'createdNewRecipeUser': true,
      }, headers: _tokenHeaders()),
    );

    final result = await auth.signIn(SocialProvider.google, role: 'requester');

    final request = sent.single;
    expect(request.url, Uri.parse('http://auth.test/auth/signinup'));
    expect(request.headers['rid'], 'thirdparty');
    expect(request.headers['st-auth-mode'], 'header');
    expect(bodyOf(request), {
      'thirdPartyId': 'google',
      'oAuthTokens': {'id_token': 'google-id-token'},
      'role': 'requester',
    });
    final session = (result as Ok<Session, AuthFailure>).value;
    expect(session.user.email, 'ana@gmail.com');
    expect(session.isNewAccount, isTrue);
  });

  test(
    'Apple names the app by its role, as mano-auth keys its clients',
    () async {
      final auth = authWith(
        (_) async => _ok({
          'status': 'OK',
          'createdNewRecipeUser': false,
        }, headers: _tokenHeaders()),
      );

      await auth.signIn(SocialProvider.apple, role: 'provider');

      expect(bodyOf(sent.single), {
        'thirdPartyId': 'apple',
        'clientType': 'provider',
        'oAuthTokens': {'id_token': 'apple-id-token'},
        'role': 'provider',
      });
    },
  );

  test('closing the sheet is SignInCancelled and calls nobody', () async {
    final auth = authWith(
      (_) async => _ok({}),
      sources: {SocialProvider.google: _FakeSource(() async => null)},
    );

    final result = await auth.signIn(SocialProvider.google, role: 'requester');

    expect(
      (result as Err<Session, AuthFailure>).failure,
      isA<SignInCancelled>(),
    );
    expect(sent, isEmpty);
  });

  test('a provider this build has no client for is AuthUnavailable', () async {
    final auth = authWith((_) async => _ok({}), sources: {});

    final result = await auth.signIn(SocialProvider.apple, role: 'requester');

    expect(
      (result as Err<Session, AuthFailure>).failure,
      isA<AuthUnavailable>(),
    );
  });

  test('a platform failure is AuthUnavailable', () async {
    final auth = authWith(
      (_) async => _ok({}),
      sources: {
        SocialProvider.google: _FakeSource(
          () async => throw const IdTokenUnavailable('no play services'),
        ),
      },
    );

    final result = await auth.signIn(SocialProvider.google, role: 'requester');

    expect(
      (result as Err<Session, AuthFailure>).failure,
      isA<AuthUnavailable>(),
    );
  });

  test('a provider mano-auth does not serve is AuthUnavailable', () async {
    final auth = authWith((_) async => http.Response('Not Found', 404));

    final result = await auth.signIn(SocialProvider.google, role: 'requester');

    expect(
      (result as Err<Session, AuthFailure>).failure,
      isA<AuthUnavailable>(),
    );
  });

  test('a refusal is SignInRejected', () async {
    final auth = authWith(
      (_) async => _ok({'status': 'SIGN_IN_UP_NOT_ALLOWED', 'reason': 'x'}),
    );

    final result = await auth.signIn(SocialProvider.google, role: 'requester');

    expect(
      (result as Err<Session, AuthFailure>).failure,
      isA<SignInRejected>(),
    );
  });
}
