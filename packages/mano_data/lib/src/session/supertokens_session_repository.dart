import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mano_domain/mano_domain.dart';

import 'token_store.dart';

/// [SessionRepository] over the SuperTokens frontend driver interface, header mode.
final class SuperTokensSessionRepository implements SessionRepository {
  SuperTokensSessionRepository({
    required Uri apiDomain,
    required TokenStore tokens,
    String apiBasePath = '/auth',
    http.Client? httpClient,
  }) : _base = apiDomain.resolve(apiBasePath),
       _tokens = tokens, // ignore: prefer_initializing_formals
       _http = httpClient ?? http.Client();

  final Uri _base;
  final TokenStore _tokens;
  final http.Client _http;

  // The current session, kept for sign-out and to remember the email across refreshes.
  Session? _current;

  static const _headerMode = {'st-auth-mode': 'header'};

  @override
  Future<Result<Session, AuthFailure>> signIn(Credentials credentials) =>
      _emailPassword('signin', credentials);

  @override
  Future<Result<Session, AuthFailure>> signUp(Credentials credentials) =>
      _emailPassword('signup', credentials);

  @override
  Future<Result<Session?, AuthFailure>> restore() async {
    if (await _tokens.read() == null) return const Ok(null);
    return switch (await refresh()) {
      Ok(:final value) => Ok(value),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<Result<Session, AuthFailure>> refresh() async {
    final refreshToken = await _tokens.read();
    if (refreshToken == null) return const Err(SessionExpired());

    final http.Response response;
    try {
      response = await _http.post(
        _route('session/refresh'),
        headers: {..._headerMode, 'Authorization': 'Bearer $refreshToken'},
      );
    } on Object catch (error) {
      return Err(_unreachable(error));
    }

    if (response.statusCode == 401) {
      await _tokens.clear();
      _current = null;
      return const Err(SessionExpired());
    }
    if (response.statusCode != 200) {
      return Err(
        AuthUnavailable(detail: 'refresh returned ${response.statusCode}'),
      );
    }
    return Ok(await _adopt(response, email: _current?.user.email));
  }

  @override
  Future<void> signOut() async {
    final accessToken = _current?.accessToken;
    _current = null;
    await _tokens.clear();
    if (accessToken == null) return;
    try {
      await _http.post(
        _route('signout'),
        headers: {..._headerMode, 'Authorization': 'Bearer $accessToken'},
      );
    } on Object {
      // Local credentials are gone; the server session expires on its own.
    }
  }

  Future<Result<Session, AuthFailure>> _emailPassword(
    String route,
    Credentials credentials,
  ) async {
    final http.Response response;
    try {
      response = await _http.post(
        _route(route),
        headers: {
          ..._headerMode,
          'rid': 'emailpassword',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'formFields': [
            {'id': 'email', 'value': credentials.email},
            {'id': 'password', 'value': credentials.password},
          ],
        }),
      );
    } on Object catch (error) {
      return Err(_unreachable(error));
    }

    if (response.statusCode != 200) {
      return Err(
        AuthUnavailable(detail: '$route returned ${response.statusCode}'),
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return switch (body['status']) {
      'OK' => Ok(await _adopt(response, email: credentials.email)),
      'FIELD_ERROR' => Err(SignInRejected(reason: _fieldErrors(body))),
      final status => Err(SignInRejected(reason: '$status')),
    };
  }

  // Turns the token headers into a session and persists the refresh token.
  Future<Session> _adopt(http.Response response, {String? email}) async {
    final headers = response.headers;
    final accessToken = headers['st-access-token'];
    final frontToken = headers['front-token'];
    if (accessToken == null || frontToken == null) {
      throw StateError('SuperTokens answered without session tokens');
    }
    final refreshToken = headers['st-refresh-token'];
    if (refreshToken != null) await _tokens.write(refreshToken);

    final front = jsonDecode(
      utf8.decode(base64.decode(base64.normalize(frontToken))),
    ) as Map<String, dynamic>;
    final payload = (front['up'] as Map<String, dynamic>?) ?? const {};
    final roleClaim = payload['st-role'] as Map<String, dynamic>?;

    return _current = Session(
      user: AuthenticatedUser(
        subject: front['uid'] as String,
        email: email ?? payload['email'] as String?,
        roles: {...?(roleClaim?['v'] as List?)?.cast<String>()},
      ),
      accessToken: accessToken,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        front['ate'] as int,
        isUtc: true,
      ),
    );
  }

  Uri _route(String path) => _base.replace(path: '${_base.path}/$path');

  static String _fieldErrors(Map<String, dynamic> body) =>
      ((body['formFields'] as List?) ?? const [])
          .map((field) => '${field['id']}: ${field['error']}')
          .join('; ');

  static AuthFailure _unreachable(Object error) => switch (error) {
    SocketException() || http.ClientException() => AuthUnavailable(
      detail: 'cannot reach SuperTokens: $error',
    ),
    _ => throw error,
  };
}
