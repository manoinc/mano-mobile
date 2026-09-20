import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

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
  (ref) => HttpGatewayClient(ref.watch(manoConfigProvider)),
);

/// Persistent credential storage.
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => const SecureTokenStore(),
);

/// The composition step that matters: an adapter bound to the domain's port.
///
/// Everything above depends on [SessionRepository], the interface — never on
/// a concrete class. That is what makes this line the *entire* footprint of
/// an auth-provider decision: no auth vendor has been chosen yet, so this
/// defaults to [_NoAuthProviderChosen], and the moment one is, replacing this
/// one override is the whole migration. The UI, the domain, and every test
/// above this line do not change.
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => const _NoAuthProviderChosen(),
);

/// Stands in for [SessionRepository] until a real provider is wired up here.
///
/// [restore] reports `Ok(null)` rather than a failure, so a cold start looks
/// like an ordinary first launch: the sign-in screen renders cleanly, with no
/// notice on it. The notice only appears once someone actually tries to sign
/// in, which is the point at which "there is nothing to try yet" becomes true
/// information rather than noise on a screen nobody has touched.
final class _NoAuthProviderChosen implements SessionRepository {
  const _NoAuthProviderChosen();

  static const _notWired = AuthUnavailable(
    detail: 'no SessionRepository has been configured',
  );

  @override
  Future<Result<Session?, AuthFailure>> restore() async => const Ok(null);

  @override
  Future<Result<Session, AuthFailure>> signIn() async =>
      const Err(_notWired);

  @override
  Future<Result<Session, AuthFailure>> refresh() async =>
      const Err(SessionExpired());

  @override
  Future<void> signOut() async {}
}
