import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

ReferralCode _code(String raw) => ReferralCode.parse(raw)!;

void main() {
  test('a known colleague code is redeemed once', () async {
    final redeemer = MockWorkerReferralRedeemer();

    expect(
      (await redeemer.redeem(_code(MockWorkerReferralRedeemer.colleague))).isOk,
      isTrue,
    );
    expect(
      (await redeemer.redeem(_code(MockWorkerReferralRedeemer.colleague)))
          .failureOrNull,
      ReferralRedemptionFailure.alreadyRedeemed,
    );
  });

  test('an unknown code is not found', () async {
    expect(
      (await MockWorkerReferralRedeemer().redeem(_code('RP-00000000')))
          .failureOrNull,
      ReferralRedemptionFailure.unknownCode,
    );
  });

  test('your own code is refused', () async {
    expect(
      (await MockWorkerReferralRedeemer().redeem(
        _code(MockWorkerReferralRedeemer.own),
      )).failureOrNull,
      ReferralRedemptionFailure.ownCode,
    );
  });
}
