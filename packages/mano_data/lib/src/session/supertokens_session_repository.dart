import 'package:http/http.dart' as http;
import 'package:mano_domain/mano_domain.dart';

import 'supertokens_fdi.dart';
import 'token_store.dart';

/// [SessionRepository] over the SuperTokens frontend driver interface, header mode.
final class SuperTokensSessionRepository implements SessionRepository {
  SuperTokensSessionRepository({
    required Uri apiDomain,
    required TokenStore tokens,
    String apiBasePath = '/auth',
    http.Client? httpClient,
  }) : _fdi = SuperTokensFdi(
         apiDomain: apiDomain,
         tokens: tokens,
         apiBasePath: apiBasePath,
         httpClient: httpClient,
       );

  /// Shares [fdi] with the phone and social adapters, so any session refreshes and signs out here.
  SuperTokensSessionRepository.over(SuperTokensFdi fdi) : _fdi = fdi;

  final SuperTokensFdi _fdi;

  @override
  Future<Result<Session, AuthFailure>> signIn(Credentials credentials) =>
      _emailPassword('signin', credentials);

  @override
  Future<Result<Session, AuthFailure>> signUp(
    Credentials credentials, {
    required String role,
  }) => _emailPassword('signup', credentials, role: role);

  @override
  Future<Result<Session?, AuthFailure>> restore() async {
    if (await _fdi.tokens.read() == null) return const Ok(null);
    return switch (await refresh()) {
      Ok(:final value) => Ok(value),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<Result<Session, AuthFailure>> refresh() async {
    final refreshToken = await _fdi.tokens.read();
    if (refreshToken == null) return const Err(SessionExpired());

    final http.Response response;
    try {
      response = await _fdi.post('session/refresh', bearer: refreshToken);
    } on Object catch (error) {
      return Err(SuperTokensFdi.unreachable(error));
    }

    if (response.statusCode == 401) {
      await _fdi.tokens.clear();
      _fdi.current = null;
      return const Err(SessionExpired());
    }
    if (response.statusCode != 200) {
      return Err(
        AuthUnavailable(detail: 'refresh returned ${response.statusCode}'),
      );
    }
    return Ok(await _fdi.adopt(response, email: _fdi.current?.user.email));
  }

  @override
  Future<void> signOut() async {
    final accessToken = _fdi.current?.accessToken;
    _fdi.current = null;
    await _fdi.tokens.clear();
    if (accessToken == null) return;
    try {
      await _fdi.post('signout', bearer: accessToken);
    } on Object {
      // Local credentials are gone; the server session expires on its own.
    }
  }

  Future<Result<Session, AuthFailure>> _emailPassword(
    String route,
    Credentials credentials, {
    String? role,
  }) async {
    final http.Response response;
    try {
      response = await _fdi.post(
        route,
        rid: 'emailpassword',
        body: {
          'formFields': [
            {'id': 'email', 'value': credentials.email},
            {'id': 'password', 'value': credentials.password},
            if (role != null) {'id': 'role', 'value': role},
          ],
        },
      );
    } on Object catch (error) {
      return Err(SuperTokensFdi.unreachable(error));
    }

    final Map<String, dynamic> body;
    switch (SuperTokensFdi.okBody(response, route)) {
      case Ok(:final value):
        body = value;
      case Err(:final failure):
        return Err(failure);
    }
    return switch (body['status']) {
      'OK' => Ok(await _fdi.adopt(response, email: credentials.email)),
      'WRONG_CREDENTIALS_ERROR' => const Err(WrongCredentials()),
      'FIELD_ERROR' when route == 'signup' && _failsOn(body, 'email') =>
        const Err(EmailAlreadyRegistered()),
      'FIELD_ERROR' => Err(SignInRejected(reason: _fieldErrors(body))),
      final status => Err(SignInRejected(reason: '$status')),
    };
  }

  // Whether the field errors name [id]; mano-auth only flags email when it is taken.
  static bool _failsOn(Map<String, dynamic> body, String id) =>
      ((body['formFields'] as List?) ?? const []).any(
        (field) => field['id'] == id,
      );

  static String _fieldErrors(Map<String, dynamic> body) =>
      ((body['formFields'] as List?) ?? const [])
          .map((field) => '${field['id']}: ${field['error']}')
          .join('; ');
}
