import 'package:mano_domain/mano_domain.dart';

import 'gateway_transport.dart';

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

/// [GatewayClient] over [GatewayTransport].
final class HttpGatewayClient implements GatewayClient {
  HttpGatewayClient(this._transport);

  final GatewayTransport _transport;

  static const String _meQuery = '{ me { subject username email roles } }';

  @override
  Future<AuthenticatedUser> me(String accessToken) async {
    final Map<String, dynamic> data;
    try {
      data = await _transport.run(_meQuery, accessToken: accessToken);
    } on GatewayRejected catch (error) {
      // "authentication required" is how the gateway says no principal arrived.
      throw GatewayUnauthorized(error.message);
    }

    final me = data['me'];
    if (me is! Map<String, dynamic>) {
      throw StateError('gateway returned neither `me` nor an error');
    }
    return _toUser(me);
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
