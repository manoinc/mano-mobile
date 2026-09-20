import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mano_domain/mano_domain.dart';

import '../config/mano_config.dart';

/// The gateway rejected the credential.
final class GatewayUnauthorized implements Exception {
  const GatewayUnauthorized(this.detail);

  final String detail;

  @override
  String toString() => 'GatewayUnauthorized($detail)';
}

/// The gateway could not be reached, or failed on its own side.
final class GatewayUnavailable implements Exception {
  const GatewayUnavailable(this.detail);

  final String detail;

  @override
  String toString() => 'GatewayUnavailable($detail)';
}

/// Mano's GraphQL API, behind an interface.
abstract interface class GatewayClient {
  /// Asks the gateway who [accessToken] belongs to.
  ///
  /// This is what makes an [AuthenticatedUser] trustworthy. The app could
  /// decode the token itself, but decoding is not verifying: only the gateway
  /// holds the realm's public keys, checks the signature, issuer, audience and
  /// expiry, and merges realm with client roles. Asking it means the identity
  /// the app acts on is one the backend has already vouched for.
  Future<AuthenticatedUser> me(String accessToken);
}

/// [GatewayClient] over plain HTTP.
///
/// No GraphQL client library, deliberately. There is one query and no agreed
/// schema; adopting a client and its cache now would be committing to a shape
/// nobody has settled. When the schema exists, code generation starts paying
/// for itself and this is the only file that changes.
final class HttpGatewayClient implements GatewayClient {
  HttpGatewayClient(this._config, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final ManoConfig _config;
  final http.Client _http;

  static const String _meQuery = '{ me { subject username email roles } }';

  @override
  Future<AuthenticatedUser> me(String accessToken) async {
    final http.Response response;
    try {
      response = await _http.post(
        Uri.parse(_config.gatewayGraphQlUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'query': _meQuery}),
      );
    } on SocketException catch (error) {
      throw GatewayUnavailable('cannot reach the gateway: $error');
    } on http.ClientException catch (error) {
      throw GatewayUnavailable('gateway request failed: $error');
    }

    // The gateway currently maps every authentication error onto 401, so this
    // covers both "your token is bad" and "the gateway could not reach its
    // identity provider". Until it distinguishes them, so must we: treat it
    // as a credential problem, because that is the case the user can act on.
    if (response.statusCode == 401) {
      throw GatewayUnauthorized('gateway returned 401');
    }
    if (response.statusCode != 200) {
      throw GatewayUnavailable('gateway returned ${response.statusCode}');
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException catch (error) {
      throw GatewayUnavailable('gateway returned malformed JSON: $error');
    }

    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      final message = '${(errors.first as Map<String, dynamic>)['message']}';
      // "authentication required" is the gateway's way of saying the request
      // arrived without a principal.
      throw GatewayUnauthorized(message);
    }

    final data = body['data'];
    if (data is! Map<String, dynamic> || data['me'] is! Map<String, dynamic>) {
      // A 200 with no `me` and no errors is the gateway breaking its own
      // contract. Nothing sensible to do but fail loudly.
      throw StateError('gateway returned neither `me` nor an error');
    }

    return _toUser(data['me'] as Map<String, dynamic>);
  }

  AuthenticatedUser _toUser(Map<String, dynamic> me) {
    final subject = me['subject'];
    if (subject is! String) {
      throw StateError('gateway returned a principal with no subject');
    }

    return AuthenticatedUser(
      subject: subject,
      username: me['username'] as String?,
      email: me['email'] as String?,
      roles: switch (me['roles']) {
        final List<dynamic> roles => roles.cast<String>().toSet(),
        _ => const <String>{},
      },
    );
  }
}
