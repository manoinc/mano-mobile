import '../result.dart';
import '../shared/data_failure.dart';

/// Saves the professional behind a referral code (gateway: `linkWorkerByReferralCode`).
abstract interface class ReferralLinker {
  /// The professional's display name; an unknown code is [DataNotFound].
  Future<Result<String, DataFailure>> link(String code);
}
