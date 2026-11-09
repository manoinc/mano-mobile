import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../home/greeting_name.dart';
import '../onboarding/onboarding_flow.dart';
import '../offline_marketplace_provider.dart';
import '../onboarding/onboarding_notifier.dart';
import '../session_notifier.dart';
import '../session_providers.dart';

/// What the profile starts with: the name typed at sign-up and the account's email.
ClientProfile clientProfileSeed(AuthenticatedUser? user, OnboardingFlow flow) {
  final email =
      user?.email ??
      ((user?.username ?? '').contains('@') ? user!.username! : '');
  return ClientProfile(
    displayName: requesterGreetingName(user, flow) ?? '',
    email: email,
  );
}

// Live on D2; the seed fills what the profiles service does not know yet.
final clientProfileRepositoryProvider = Provider<ClientProfileRepository>((
  ref,
) {
  final seed = clientProfileSeed(
    ref.watch(currentUserProvider),
    ref.read(onboardingFlowProvider),
  );
  return ref.watch(offlineMarketplaceProvider)
      ? MockClientProfileRepository(initial: seed)
      : GatewayClientProfileRepository(
          ref.watch(gatewayTransportProvider),
          seed: seed,
        );
});

final clientProfileProvider = FutureProvider<ClientProfile>(
  (ref) => ref.watch(clientProfileRepositoryProvider).profile(),
);

/// Profile writes; each success refreshes [clientProfileProvider].
final class ClientProfileActions extends Notifier<void> {
  @override
  void build() {}

  Future<Result<ClientProfile, DataFailure>> save(ClientProfile profile) =>
      _refreshing(ref.read(clientProfileRepositoryProvider).update(profile));

  Future<Result<ClientProfile, DataFailure>> setPhoto(MediaAttachment photo) =>
      _refreshing(ref.read(clientProfileRepositoryProvider).updatePhoto(photo));

  Future<Result<ClientProfile, DataFailure>> _refreshing(
    Future<Result<ClientProfile, DataFailure>> write,
  ) async {
    final result = await write;
    if (result.isOk) ref.invalidate(clientProfileProvider);
    return result;
  }
}

final clientProfileActionsProvider =
    NotifierProvider<ClientProfileActions, void>(ClientProfileActions.new);
