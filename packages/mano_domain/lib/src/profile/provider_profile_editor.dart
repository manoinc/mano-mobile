import '../result.dart';
import '../shared/data_failure.dart';
import 'provider_profile.dart';
import 'provider_profile_draft.dart';

/// Saves the signed-in provider's own profile.
abstract interface class ProviderProfileEditor {
  Future<Result<ProviderProfile, DataFailure>> save(ProviderProfileDraft draft);
}
