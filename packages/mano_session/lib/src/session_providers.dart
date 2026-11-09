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
  final fdi = ref.watch(superTokensFdiProvider);
  if (fdi == null) return const _NoAuthProviderChosen();
  return SuperTokensSessionRepository.over(fdi);
});

/// The one SuperTokens client every way in shares; `null` until an API domain is configured.
final superTokensFdiProvider = Provider<SuperTokensFdi?>((ref) {
  final apiDomain = ref.watch(manoConfigProvider).authApiDomain;
  if (apiDomain == null) return null;
  return SuperTokensFdi(
    apiDomain: Uri.parse(apiDomain),
    tokens: ref.watch(tokenStoreProvider),
  );
});

/// Phone + code sign-in; reports [AuthUnavailable] until an API domain is configured.
final passwordlessAuthProvider = Provider<PasswordlessAuth>((ref) {
  final fdi = ref.watch(superTokensFdiProvider);
  if (fdi == null) return const _NoPasswordless();
  return SupertokensPasswordlessAuth(fdi);
});

/// Google and Apple; a provider without a client in this build reports [AuthUnavailable].
final socialAuthProvider = Provider<SocialAuth>((ref) {
  final fdi = ref.watch(superTokensFdiProvider);
  if (fdi == null) return const _NoSocial();
  final googleClientId = ref.watch(manoConfigProvider).googleServerClientId;
  return SupertokensSocialAuth(
    fdi,
    sources: {
      if (googleClientId != null)
        SocialProvider.google: GoogleIdTokenSource(
          serverClientId: googleClientId,
        ),
      SocialProvider.apple: const AppleIdTokenSource(),
    },
  );
});

const _noAuthDomain = AuthUnavailable(detail: 'no auth API domain configured');

final class _NoPasswordless implements PasswordlessAuth {
  const _NoPasswordless();

  @override
  Future<Result<OtpChallenge, AuthFailure>> sendCode(
    String phone, {
    required String role,
  }) async => const Err(_noAuthDomain);

  @override
  Future<Result<OtpChallenge, AuthFailure>> resend(
    OtpChallenge challenge,
  ) async => const Err(_noAuthDomain);

  @override
  Future<Result<Session, AuthFailure>> verify(
    OtpChallenge challenge,
    String code,
  ) async => const Err(_noAuthDomain);
}

final class _NoSocial implements SocialAuth {
  const _NoSocial();

  @override
  Future<Result<Session, AuthFailure>> signIn(
    SocialProvider provider, {
    required String role,
  }) async => const Err(_noAuthDomain);
}

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
  Future<Result<Session, AuthFailure>> signUp(
    Credentials credentials, {
    required String role,
  }) async => const Err(_notWired);

  @override
  Future<Result<Session, AuthFailure>> refresh() async =>
      const Err(SessionExpired());

  @override
  Future<void> signOut() async {}
}
