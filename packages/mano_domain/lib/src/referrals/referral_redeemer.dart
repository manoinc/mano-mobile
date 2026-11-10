import '../result.dart';
import 'referral_code.dart';

/// Why a colleague's code was not recorded (gateway `extensions.code`).
enum ReferralRedemptionFailure {
  /// `REFERRAL_NOT_FOUND`
  unknownCode,

  /// `REFERRAL_SELF`
  ownCode,

  /// `REFERRAL_ALREADY_REDEEMED`
  alreadyRedeemed,

  /// Unreachable or refused for another reason.
  notSaved,
}

/// Records the signed-in professional as invited by [code]'s owner (gateway: `redeemWorkerReferral`).
abstract interface class WorkerReferralRedeemer {
  Future<Result<void, ReferralRedemptionFailure>> redeem(ReferralCode code);
}
