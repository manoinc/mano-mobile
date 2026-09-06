import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

/// Where this build finds Mano's services.
///
/// Deliberately unimplemented. The two apps authenticate as different OIDC
/// clients and cannot share one configuration, so each entry point must
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
/// silently authenticate as the wrong client, which surfaces much later as an
/// audience rejection nobody can explain.
final manoConfigProvider = Provider<ManoConfig>(
  (ref) => throw UnimplementedError(
    'Override manoConfigProvider in the app entry point. Each app '
    'authenticates as its own OIDC client.',
  ),
);

/// The OAuth exchange. Overridden in tests with a fake.
final oidcClientProvider = Provider<OidcClient>(
  (ref) => AppAuthOidcClient(ref.watch(manoConfigProvider)),
);

/// Mano's GraphQL API.
final gatewayClientProvider = Provider<GatewayClient>(
  (ref) => HttpGatewayClient(ref.watch(manoConfigProvider)),
);

/// Persistent credential storage.
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => const SecureTokenStore(),
);

/// The composition step that matters: adapters bound to the domain's port.
///
/// Everything above depends on [SessionRepository], the interface — never on
/// [OidcSessionRepository], the class. Swapping the implementation, or
/// substituting a fake in a test, is one override here and no change anywhere
/// else.
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => OidcSessionRepository(
    oidcClient: ref.watch(oidcClientProvider),
    gatewayClient: ref.watch(gatewayClientProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  ),
);
