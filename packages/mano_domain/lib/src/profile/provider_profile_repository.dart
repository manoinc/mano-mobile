import '../reviews/review.dart';
import 'provider_profile.dart';

/// The signed-in provider's own profile, standing and referrals.
abstract interface class ProviderProfileRepository {
  Future<ProviderProfile> profile();

  Future<ProviderStats> stats();

  /// Newest first.
  Future<List<Review>> reviews();

  Future<ReferralProgram> referral();
}
