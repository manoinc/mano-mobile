import 'package:mano_domain/mano_domain.dart';

/// Offline redemption: [colleague] is a fellow professional's code, [own] is yours.
final class MockWorkerReferralRedeemer implements WorkerReferralRedeemer {
  static const colleague = 'RP-c011ea9e';
  static const own = 'RP-0000a11e';

  bool _redeemed = false;

  @override
  Future<Result<void, ReferralRedemptionFailure>> redeem(
    ReferralCode code,
  ) async {
    if (code.value == own) return const Err(ReferralRedemptionFailure.ownCode);
    if (code.value != colleague) {
      return const Err(ReferralRedemptionFailure.unknownCode);
    }
    if (_redeemed) return const Err(ReferralRedemptionFailure.alreadyRedeemed);
    _redeemed = true;
    return const Ok(null);
  }
}
