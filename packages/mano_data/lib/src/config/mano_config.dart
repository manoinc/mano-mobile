/// Where this build of the app finds Mano's services.
///
/// Passed in at composition time rather than read from a global, so a test, a
/// staging build and a production build differ by a value instead of by a
/// conditional buried somewhere.
///
/// Deliberately holds nothing about how a user signs in. That question is
/// still open, and whichever answer it gets will have its own shape of
/// configuration (an issuer URL, an API domain, a publishable key — no way to
/// know yet). Bolting a guess onto this class now would mean unpicking it
/// later; the auth adapter that lands next can carry its own config type, or
/// grow this one, once there is a real one to fit.
final class ManoConfig {
  const ManoConfig({required this.gatewayGraphQlUrl});

  /// The GraphQL endpoint of `mano-gateway`.
  final String gatewayGraphQlUrl;
}
