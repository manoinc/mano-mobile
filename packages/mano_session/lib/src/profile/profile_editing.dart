import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import 'profile_providers.dart';

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
