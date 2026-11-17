/// Where this build of the app finds Mano's services, passed in at composition time.
final class ManoConfig {
  const ManoConfig({
    required this.gatewayGraphQlUrl,
    required this.appRole,
    this.authApiDomain,
    this.approveIdentityChecks = false,
    this.googleServerClientId,
    this.inviteLinkBase = 'https://manoapp.co/r/',
  });

  /// The GraphQL endpoint of `mano-gateway`.
  final String gatewayGraphQlUrl;

  /// The `ManoRole` this app signs new accounts up as.
  final String appRole;

  /// The SuperTokens API domain; `null` leaves sign-in unconfigured.
  final String? authApiDomain;

  /// Debug only: the mock identity check approves at once, so the gate can be walked.
  final bool approveIdentityChecks;

  /// mano-auth's Google web client ID, the audience of Google id tokens; `null` turns Google off.
  final String? googleServerClientId;

  /// Where a professional's invite link points; the code is appended.
  final String inviteLinkBase;

  /// The link a professional shares to invite a colleague.
  Uri inviteLink(String code) =>
      Uri.parse(inviteLinkBase).resolve(Uri.encodeComponent(code));

  /// The gateway's `graphql-transport-ws` socket, beside the GraphQL endpoint.
  String get gatewaySubscriptionUrl {
    final http = Uri.parse(gatewayGraphQlUrl);
    return http
        .replace(
          scheme: http.scheme == 'https' ? 'wss' : 'ws',
          path: '/subscription',
        )
        .toString();
  }
}
