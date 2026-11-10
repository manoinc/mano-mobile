import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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

/// The gateway answered with GraphQL errors (not found, not allowed, invalid).
final class GatewayRejected implements Exception {
  const GatewayRejected(this.message, {this.code});

  final String message;

  /// The error's `extensions.code`, when the gateway sets one.
  final String? code;

  @override
  String toString() => 'GatewayRejected($message)';
}

/// GraphQL over plain HTTP POST; every gateway adapter goes through this.
final class GatewayTransport {
  GatewayTransport(
    this._config, {
    http.Client? httpClient,
    Future<String?> Function()? accessToken,
  }) : _http = httpClient ?? http.Client(),
       _accessToken = accessToken; // ignore: prefer_initializing_formals

  final ManoConfig _config;
  final http.Client _http;

  // Supplies the session's token when a call does not pass one explicitly.
  final Future<String?> Function()? _accessToken;

  /// Returns the `data` object, or throws one of the `Gateway*` exceptions.
  Future<Map<String, dynamic>> run(
    String document, {
    Map<String, Object?> variables = const {},
    String? accessToken,
  }) async {
    final bearer = accessToken ?? await _accessToken?.call();
    final http.Response response;
    try {
      response = await _http.post(
        Uri.parse(_config.gatewayGraphQlUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': ?(bearer == null ? null : 'Bearer $bearer'),
        },
        body: jsonEncode({'query': document, 'variables': variables}),
      );
    } on SocketException catch (error) {
      throw GatewayUnavailable('cannot reach the gateway: $error');
    } on http.ClientException catch (error) {
      throw GatewayUnavailable('gateway request failed: $error');
    }

    // The gateway maps every authentication error onto 401, IdP outages included.
    if (response.statusCode == 401) {
      throw const GatewayUnauthorized('gateway returned 401');
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
      final first = errors.first as Map<String, dynamic>;
      final extensions = first['extensions'];
      throw GatewayRejected(
        '${first['message']}',
        code: extensions is Map ? extensions['code'] as String? : null,
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw StateError('gateway returned neither data nor errors');
    }
    return data;
  }
}
