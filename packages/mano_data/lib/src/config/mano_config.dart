/// Where this build of the app finds Mano's services, passed in at composition time.
final class ManoConfig {
  const ManoConfig({required this.gatewayGraphQlUrl, this.authApiDomain});

  /// The GraphQL endpoint of `mano-gateway`.
  final String gatewayGraphQlUrl;

  /// The SuperTokens API domain; `null` leaves sign-in unconfigured.
  final String? authApiDomain;
}
