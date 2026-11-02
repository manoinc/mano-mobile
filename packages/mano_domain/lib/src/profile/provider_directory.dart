import '../result.dart';
import '../shared/data_failure.dart';
import 'public_provider_profile.dart';

/// Looks up any professional's public profile by id.
abstract interface class ProviderDirectory {
  Future<Result<PublicProviderProfile, DataFailure>> profile(String providerId);
}
