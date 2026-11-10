import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_transport.dart';

/// [WorkerReferralRedeemer] over `redeemWorkerReferral`; the error's `extensions.code` picks the failure.
final class GatewayWorkerReferralRedeemer implements WorkerReferralRedeemer {
  GatewayWorkerReferralRedeemer(this._transport);

  final GatewayTransport _transport;

  static const _redeem = '''
mutation RedeemWorkerReferral(\$code: String!) {
  redeemWorkerReferral(code: \$code) { id }
}''';

  @override
  Future<Result<void, ReferralRedemptionFailure>> redeem(
    ReferralCode code,
  ) async {
    try {
      await _transport.run(_redeem, variables: {'code': code.value});
      return const Ok(null);
    } on GatewayRejected catch (e) {
      return Err(switch (e.code) {
        'REFERRAL_NOT_FOUND' => ReferralRedemptionFailure.unknownCode,
        'REFERRAL_SELF' => ReferralRedemptionFailure.ownCode,
        'REFERRAL_ALREADY_REDEEMED' =>
          ReferralRedemptionFailure.alreadyRedeemed,
        _ => ReferralRedemptionFailure.notSaved,
      });
    } on GatewayUnavailable {
      return const Err(ReferralRedemptionFailure.notSaved);
    }
  }
}
