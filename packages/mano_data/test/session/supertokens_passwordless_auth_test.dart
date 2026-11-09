import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

final _expiry = DateTime.utc(2026, 11, 8, 10);

Map<String, String> _tokenHeaders() => {
  'st-access-token': 'access-1',
  'st-refresh-token': 'refresh-1',
  'front-token': base64.encode(
    utf8.encode(
      jsonEncode({
        'uid': 'user-9',
        'ate': _expiry.millisecondsSinceEpoch,
        'up': {
          'st-role': {
            'v': ['provider'],
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

const _challenge = OtpChallenge(
  deviceId: 'dev',
  preAuthSessionId: 'pre',
  phone: '+573001234567',
);

void main() {
  late List<http.Request> sent;
  late InMemoryTokenStore store;
  late SuperTokensFdi fdi;

  SupertokensPasswordlessAuth authWith(
    Future<http.Response> Function(http.Request) handler,
  ) {
    sent = [];
    store = InMemoryTokenStore();
    fdi = SuperTokensFdi(
      apiDomain: Uri.parse('http://auth.test'),
      tokens: store,
      httpClient: MockClient((request) {
        sent.add(request);
        return handler(request);
      }),
    );
    return SupertokensPasswordlessAuth(fdi);
  }

  Map<String, dynamic> bodyOf(http.Request request) =>
      jsonDecode(request.body) as Map<String, dynamic>;

  group('sendCode', () {
    test('asks for a code in header mode with the passwordless rid', () async {
      final auth = authWith(
        (_) async => _ok({
          'status': 'OK',
          'deviceId': 'dev',
          'preAuthSessionId': 'pre',
          'flowType': 'USER_INPUT_CODE',
        }),
      );

      final result = await auth.sendCode('+573001234567', role: 'provider');

      final request = sent.single;
      expect(request.url, Uri.parse('http://auth.test/auth/signinup/code'));
      expect(request.headers['rid'], 'passwordless');
      expect(request.headers['st-auth-mode'], 'header');
      expect(bodyOf(request), {'phoneNumber': '+573001234567'});
      final challenge = (result as Ok<OtpChallenge, AuthFailure>).value;
      expect(challenge.deviceId, 'dev');
      expect(challenge.preAuthSessionId, 'pre');
      expect(challenge.phone, '+573001234567');
    });

    test('a refused number is SignInRejected', () async {
      final auth = authWith(
        (_) async =>
            _ok({'status': 'GENERAL_ERROR', 'message': 'invalid phone'}),
      );

      final result = await auth.sendCode('+57', role: 'requester');

      expect(
        (result as Err<OtpChallenge, AuthFailure>).failure,
        isA<SignInRejected>(),
      );
    });

    test('an unreachable server is AuthUnavailable', () async {
      final auth = authWith((_) async => throw const SocketException('down'));

      final result = await auth.sendCode('+573001234567', role: 'requester');

      expect(
        (result as Err<OtpChallenge, AuthFailure>).failure,
        isA<AuthUnavailable>(),
      );
    });
  });

  group('resend', () {
    test('re-sends for the same device', () async {
      final auth = authWith((_) async => _ok({'status': 'OK'}));

      final result = await auth.resend(_challenge);

      expect(sent.single.url.path, '/auth/signinup/code/resend');
      expect(bodyOf(sent.single), {
        'deviceId': 'dev',
        'preAuthSessionId': 'pre',
      });
      expect((result as Ok<OtpChallenge, AuthFailure>).value, same(_challenge));
    });

    test('a flow that has to restart is CodeExpired', () async {
      final auth = authWith((_) async => _ok({'status': 'RESTART_FLOW_ERROR'}));

      final result = await auth.resend(_challenge);

      expect(
        (result as Err<OtpChallenge, AuthFailure>).failure,
        isA<CodeExpired>(),
      );
    });
  });

  group('verify', () {
    test('consumes the code with the role it was sent for', () async {
      final auth = authWith((request) async {
        if (request.url.path.endsWith('/code')) {
          return _ok({
            'status': 'OK',
            'deviceId': 'dev',
            'preAuthSessionId': 'pre',
          });
        }
        return _ok({
          'status': 'OK',
          'createdNewRecipeUser': true,
        }, headers: _tokenHeaders());
      });
      await auth.sendCode('+573001234567', role: 'provider');

      final result = await auth.verify(_challenge, ' 123456 ');

      final consume = sent.last;
      expect(consume.url.path, '/auth/signinup/code/consume');
      expect(consume.headers['rid'], 'passwordless');
      expect(bodyOf(consume), {
        'deviceId': 'dev',
        'preAuthSessionId': 'pre',
        'userInputCode': '123456',
        'role': 'provider',
      });
      final session = (result as Ok<Session, AuthFailure>).value;
      expect(session.user.subject, 'user-9');
      expect(session.user.isProvider, isTrue);
      expect(session.user.email, isNull);
      expect(session.isNewAccount, isTrue);
      expect(await store.read(), 'refresh-1');
      expect(fdi.current, session);
    });

    test('a returning account is not new', () async {
      final auth = authWith(
        (_) async => _ok({
          'status': 'OK',
          'createdNewRecipeUser': false,
        }, headers: _tokenHeaders()),
      );

      final result = await auth.verify(_challenge, '123456');

      expect((result as Ok<Session, AuthFailure>).value.isNewAccount, isFalse);
    });

    test('a wrong code says how many attempts are left', () async {
      final auth = authWith(
        (_) async => _ok({
          'status': 'INCORRECT_USER_INPUT_CODE_ERROR',
          'failedCodeInputAttemptCount': 1,
          'maximumCodeInputAttempts': 5,
        }),
      );

      final result = await auth.verify(_challenge, '000000');

      final failure = (result as Err<Session, AuthFailure>).failure;
      expect(failure, isA<InvalidCode>());
      expect((failure as InvalidCode).attemptsLeft, 4);
    });

    test('the last wrong code is TooManyAttempts', () async {
      final auth = authWith(
        (_) async => _ok({
          'status': 'INCORRECT_USER_INPUT_CODE_ERROR',
          'failedCodeInputAttemptCount': 5,
          'maximumCodeInputAttempts': 5,
        }),
      );

      final result = await auth.verify(_challenge, '000000');

      expect(
        (result as Err<Session, AuthFailure>).failure,
        isA<TooManyAttempts>(),
      );
    });

    test('an expired code or a dead flow is CodeExpired', () async {
      for (final status in [
        'EXPIRED_USER_INPUT_CODE_ERROR',
        'RESTART_FLOW_ERROR',
      ]) {
        final auth = authWith((_) async => _ok({'status': status}));

        final result = await auth.verify(_challenge, '123456');

        expect(
          (result as Err<Session, AuthFailure>).failure,
          isA<CodeExpired>(),
        );
      }
    });

    test('a server error is AuthUnavailable', () async {
      final auth = authWith((_) async => http.Response('boom', 500));

      final result = await auth.verify(_challenge, '123456');

      expect(
        (result as Err<Session, AuthFailure>).failure,
        isA<AuthUnavailable>(),
      );
    });
  });
}
