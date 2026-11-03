import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import 'profile_providers.dart';

// Mock: updateWorkerProfile is a gateway stub with no bio or skills.
final providerProfileEditorProvider = Provider<ProviderProfileEditor>(
  (ref) => ref.watch(mockProviderProfileProvider),
);

/// Saving the provider's own profile; a success refreshes Perfil.
final class ProviderProfileActions extends Notifier<void> {
  @override
  void build() {}

  Future<Result<ProviderProfile, DataFailure>> save(
    ProviderProfileDraft draft,
  ) async {
    final result = await ref.read(providerProfileEditorProvider).save(draft);
    if (result.isOk) ref.invalidate(providerProfileProvider);
    return result;
  }
}

final providerProfileActionsProvider =
    NotifierProvider<ProviderProfileActions, void>(ProviderProfileActions.new);
