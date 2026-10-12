import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import 'session_notifier.dart';

/// Where this build finds Mano's services.
///
/// Deliberately unimplemented. The two apps will likely authenticate as
/// different clients once a provider is chosen, so each entry point must
/// override this:
///
/// ```dart
/// runApp(
///   ProviderScope(
///     overrides: [manoConfigProvider.overrideWithValue(requesterConfig)],
///     child: const RequesterApp(),
///   ),
/// );
/// ```
///
/// Failing loudly at startup is the point: a default here would let an app
/// silently talk to the wrong endpoint, which surfaces much later as a
/// rejection nobody can explain.
final manoConfigProvider = Provider<ManoConfig>(
  (ref) => throw UnimplementedError(
    'Override manoConfigProvider in the app entry point.',
  ),
);

/// Mano's GraphQL API. Nothing about this depends on how the user signed in --
/// it only needs a bearer token, whoever minted it.
final gatewayClientProvider = Provider<GatewayClient>(
  (ref) => HttpGatewayClient(ref.watch(gatewayTransportProvider)),
);

/// The HTTP pipe every gateway adapter shares.
final gatewayTransportProvider = Provider<GatewayTransport>(
  (ref) => GatewayTransport(
    ref.watch(manoConfigProvider),
    // Asked per call, so a token about to expire is renewed before it is sent.
    accessToken: () => ref.read(sessionProvider.notifier).freshAccessToken(),
  ),
);

/// Persistent credential storage.
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => const SecureTokenStore(),
);

/// The composition step that matters: an adapter bound to the domain's port.
///
/// SuperTokens when the build names an API domain, otherwise [_NoAuthProviderChosen].
/// Swapping vendors is this one provider; nothing above it changes.
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final apiDomain = ref.watch(manoConfigProvider).authApiDomain;
  if (apiDomain == null) return const _NoAuthProviderChosen();
  return SuperTokensSessionRepository(
    apiDomain: Uri.parse(apiDomain),
    tokens: ref.watch(tokenStoreProvider),
  );
});

/// Stands in until an API domain is configured: a cold start is an ordinary
/// first launch, and only an actual attempt reports [AuthUnavailable].
final class _NoAuthProviderChosen implements SessionRepository {
  const _NoAuthProviderChosen();

  static const _notWired = AuthUnavailable(
    detail: 'no SessionRepository has been configured',
  );

  @override
  Future<Result<Session?, AuthFailure>> restore() async => const Ok(null);

  @override
  Future<Result<Session, AuthFailure>> signIn(Credentials credentials) async =>
      const Err(_notWired);

  @override
  Future<Result<Session, AuthFailure>> signUp(Credentials credentials) async =>
      const Err(_notWired);

  @override
  Future<Result<Session, AuthFailure>> refresh() async =>
      const Err(SessionExpired());

  @override
  Future<void> signOut() async {}
}
