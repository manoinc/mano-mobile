import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mano_domain/mano_domain.dart';

import 'token_store.dart';

/// The SuperTokens frontend driver interface in header mode, shared by every way in.
///
/// One instance per app, so a session started by phone, Google or email is
/// the one refresh renews and sign-out revokes.
final class SuperTokensFdi {
  SuperTokensFdi({
    required Uri apiDomain,
    required this.tokens,
    String apiBasePath = '/auth',
    http.Client? httpClient,
  }) : _base = apiDomain.resolve(apiBasePath),
       _http = httpClient ?? http.Client();

  final Uri _base;
  final http.Client _http;
  final TokenStore tokens;

  /// The live session, kept for sign-out and to remember the email across refreshes.
  Session? current;

  /// Posts to `/auth/[path]`; transport errors are thrown, see [unreachable].
  Future<http.Response> post(
    String path, {
    String? rid,
    Map<String, Object?>? body,
    String? bearer,
  }) => _http.post(
    _base.replace(path: '${_base.path}/$path'),
    headers: {
      'st-auth-mode': 'header',
      'rid': ?rid,
      if (body != null) 'Content-Type': 'application/json',
      if (bearer != null) 'Authorization': 'Bearer $bearer',
    },
    body: body == null ? null : jsonEncode(body),
  );

  /// Turns the token headers into a session and persists the refresh token.
  Future<Session> adopt(
    http.Response response, {
    String? email,
    bool isNewAccount = false,
  }) async {
    final headers = response.headers;
    final accessToken = headers['st-access-token'];
    final frontToken = headers['front-token'];
    if (accessToken == null || frontToken == null) {
      throw StateError('SuperTokens answered without session tokens');
    }
    final refreshToken = headers['st-refresh-token'];
    if (refreshToken != null) await tokens.write(refreshToken);

    final front = jsonDecode(
      utf8.decode(base64.decode(base64.normalize(frontToken))),
    ) as Map<String, dynamic>;
    final payload = (front['up'] as Map<String, dynamic>?) ?? const {};
    final roleClaim = payload['st-role'] as Map<String, dynamic>?;

    return current = Session(
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
      isNewAccount: isNewAccount,
    );
  }

  /// A network failure becomes [AuthUnavailable]; anything else is a bug and is rethrown.
  static AuthFailure unreachable(Object error) => switch (error) {
    SocketException() || http.ClientException() => AuthUnavailable(
      detail: 'cannot reach SuperTokens: $error',
    ),
    _ => throw error,
  };

  /// The JSON body of a 200, or [AuthUnavailable] for any other status.
  static Result<Map<String, dynamic>, AuthFailure> okBody(
    http.Response response,
    String route,
  ) => response.statusCode == 200
      ? Ok(jsonDecode(response.body) as Map<String, dynamic>)
      : Err(AuthUnavailable(detail: '$route returned ${response.statusCode}'));
}
