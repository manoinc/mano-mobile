import 'package:http/http.dart' as http;
import 'package:mano_domain/mano_domain.dart';

import 'supertokens_fdi.dart';

/// [PasswordlessAuth] over SuperTokens' passwordless recipe: phone, six-digit code.
final class SupertokensPasswordlessAuth implements PasswordlessAuth {
  SupertokensPasswordlessAuth(this._fdi);

  final SuperTokensFdi _fdi;

  // mano-auth takes the role when the code is consumed, so it is kept from sendCode.
  String? _role;

  static const _rid = 'passwordless';

  @override
  Future<Result<OtpChallenge, AuthFailure>> sendCode(
    String phone, {
    required String role,
  }) async {
    _role = role;
    return switch (await _post('signinup/code', {'phoneNumber': phone})) {
      Ok(:final value) when value['status'] == 'OK' => Ok(
        OtpChallenge(
          deviceId: value['deviceId'] as String,
          preAuthSessionId: value['preAuthSessionId'] as String,
          phone: phone,
        ),
      ),
      Ok(:final value) => Err(_rejected(value)),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<Result<OtpChallenge, AuthFailure>> resend(
    OtpChallenge challenge,
  ) async => switch (await _post('signinup/code/resend', _handles(challenge))) {
    Ok(:final value) => switch (value['status']) {
      'OK' => Ok(challenge),
      'RESTART_FLOW_ERROR' => const Err(CodeExpired()),
      _ => Err(_rejected(value)),
    },
    Err(:final failure) => Err(failure),
  };

  @override
  Future<Result<Session, AuthFailure>> verify(
    OtpChallenge challenge,
    String code,
  ) async {
    final http.Response response;
    try {
      response = await _fdi.post(
        'signinup/code/consume',
        rid: _rid,
        body: {
          ..._handles(challenge),
          'userInputCode': code.trim(),
          'role': ?_role,
        },
      );
    } on Object catch (error) {
      return Err(SuperTokensFdi.unreachable(error));
    }
    final Map<String, dynamic> body;
    switch (SuperTokensFdi.okBody(response, 'consume')) {
      case Ok(:final value):
        body = value;
      case Err(:final failure):
        return Err(failure);
    }
    return switch (body['status']) {
      'OK' => Ok(
        await _fdi.adopt(
          response,
          isNewAccount: body['createdNewRecipeUser'] == true,
        ),
      ),
      'INCORRECT_USER_INPUT_CODE_ERROR' => Err(_wrongCode(body)),
      'EXPIRED_USER_INPUT_CODE_ERROR' ||
      'RESTART_FLOW_ERROR' => const Err(CodeExpired()),
      _ => Err(_rejected(body)),
    };
  }

  Future<Result<Map<String, dynamic>, AuthFailure>> _post(
    String route,
    Map<String, Object?> body,
  ) async {
    try {
      final response = await _fdi.post(route, rid: _rid, body: body);
      return SuperTokensFdi.okBody(response, route);
    } on Object catch (error) {
      return Err(SuperTokensFdi.unreachable(error));
    }
  }

  static Map<String, Object?> _handles(OtpChallenge challenge) => {
    'deviceId': challenge.deviceId,
    'preAuthSessionId': challenge.preAuthSessionId,
  };

  static AuthFailure _wrongCode(Map<String, dynamic> body) {
    final failed = body['failedCodeInputAttemptCount'] as int;
    final maximum = body['maximumCodeInputAttempts'] as int;
    return failed >= maximum
        ? const TooManyAttempts()
        : InvalidCode(attemptsLeft: maximum - failed);
  }

  static AuthFailure _rejected(Map<String, dynamic> body) =>
      SignInRejected(reason: '${body['status']}: ${body['message'] ?? ''}');
}
