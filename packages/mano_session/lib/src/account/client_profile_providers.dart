import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../home/greeting_name.dart';
import '../onboarding/onboarding_flow.dart';
import '../onboarding/onboarding_notifier.dart';
import '../session_notifier.dart';

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

// Mock: the gateway's updateClientProfile is a stub and profiles carry no names yet.
final clientProfileRepositoryProvider = Provider<ClientProfileRepository>(
  (ref) => MockClientProfileRepository(
    initial: clientProfileSeed(
      ref.watch(currentUserProvider),
      ref.read(onboardingFlowProvider),
    ),
  ),
);

final clientProfileProvider = FutureProvider<ClientProfile>(
  (ref) => ref.watch(clientProfileRepositoryProvider).profile(),
);

/// Profile writes; each success refreshes [clientProfileProvider].
final class ClientProfileActions extends Notifier<void> {
  @override
  void build() {}

  Future<Result<ClientProfile, DataFailure>> save(ClientProfile profile) =>
      _refreshing(ref.read(clientProfileRepositoryProvider).update(profile));

  Future<Result<ClientProfile, DataFailure>> setPhoto(String photoUrl) =>
      _refreshing(
        ref.read(clientProfileRepositoryProvider).updatePhoto(photoUrl),
      );

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
