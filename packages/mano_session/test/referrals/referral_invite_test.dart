import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

final class _Links implements InviteLinkSource {
  final controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get links => controller.stream;
}

final class _Referrer implements InstallReferrerSource {
  _Referrer(this.value);

  final String? value;
  var reads = 0;

  @override
  Future<String?> referrer() async {
    reads++;
    return value;
  }
}

final class _Redeemer implements WorkerReferralRedeemer {
  _Redeemer([this.result = const Ok(null)]);

  final Result<void, ReferralRedemptionFailure> result;
  final redeemed = <ReferralCode>[];

  @override
  Future<Result<void, ReferralRedemptionFailure>> redeem(
    ReferralCode code,
  ) async {
    redeemed.add(code);
    return result;
  }
}

final _code = ReferralCode.parse('RP-bb2cde6b')!;
final _other = ReferralCode.parse('RP-0123abcd')!;

({ProviderContainer c, _Links links, _Redeemer redeemer}) _setUp({
  String? referrer,
  _Redeemer? redeemer,
}) {
  final links = _Links();
  final r = redeemer ?? _Redeemer();
  final c = ProviderContainer.test(
    overrides: [
      inviteLinkSourceProvider.overrideWithValue(links),
      installReferrerSourceProvider.overrideWithValue(_Referrer(referrer)),
      workerReferralRedeemerProvider.overrideWithValue(r),
    ],
  );
  c.listen(referralInviteProvider, (_, _) {});
  return (c: c, links: links, redeemer: r);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('nothing is pending on an organic launch', () async {
    final (:c, links: _, redeemer: _) = _setUp();
    await _settle();
    expect(c.read(referralInviteProvider).code, isNull);
  });

  test('an invite link keeps its code', () async {
    final (:c, :links, redeemer: _) = _setUp();
    links.controller.add(Uri.parse('https://manoapp.co/r/RP-bb2cde6b'));
    await _settle();
    expect(c.read(referralInviteProvider).code, _code);
  });

  test('a link that is not an invite is ignored', () async {
    final (:c, :links, redeemer: _) = _setUp();
    links.controller.add(Uri.parse('https://manoapp.co/terminos'));
    await _settle();
    expect(c.read(referralInviteProvider).code, isNull);
  });

  test('the Play install referrer keeps its code', () async {
    final (:c, links: _, redeemer: _) = _setUp(referrer: 'ref=RP-bb2cde6b');
    await _settle();
    expect(c.read(referralInviteProvider).code, _code);
  });

  test('a link outranks the install referrer', () async {
    final (:c, :links, redeemer: _) = _setUp(referrer: 'ref=RP-0123abcd');
    links.controller.add(Uri.parse('https://manoapp.co/r/RP-bb2cde6b'));
    await _settle();
    expect(c.read(referralInviteProvider).code, _code);
  });

  test('a typed code replaces the kept one', () async {
    final (:c, links: _, redeemer: _) = _setUp(referrer: 'ref=RP-bb2cde6b');
    await _settle();
    c.read(referralInviteProvider.notifier).keep(_other);
    expect(c.read(referralInviteProvider).code, _other);
  });

  test('redeeming sends the code once and clears it quietly', () async {
    final (:c, :links, :redeemer) = _setUp();
    links.controller.add(Uri.parse('https://manoapp.co/r/RP-bb2cde6b'));
    await _settle();

    await c.read(referralInviteProvider.notifier).redeem();
    await c.read(referralInviteProvider.notifier).redeem();

    expect(redeemer.redeemed, [_code]);
    expect(c.read(referralInviteProvider).code, isNull);
    expect(c.read(referralInviteProvider).failure, isNull);
  });

  test('with nothing kept, redeeming does nothing', () async {
    final (:c, links: _, :redeemer) = _setUp();
    await c.read(referralInviteProvider.notifier).redeem();
    expect(redeemer.redeemed, isEmpty);
  });

  test('a refused code is reported once, then forgotten', () async {
    final (:c, links: _, redeemer: _) = _setUp(
      redeemer: _Redeemer(const Err(ReferralRedemptionFailure.ownCode)),
    );
    final notifier = c.read(referralInviteProvider.notifier)..keep(_code);

    await notifier.redeem();
    expect(
      c.read(referralInviteProvider).failure,
      ReferralRedemptionFailure.ownCode,
    );
    expect(c.read(referralInviteProvider).code, isNull);

    notifier.acknowledge();
    expect(c.read(referralInviteProvider).failure, isNull);
  });

  test('offline, redemption uses the mock', () {
    final c = ProviderContainer.test(
      overrides: [
        manoConfigProvider.overrideWithValue(
          const ManoConfig(
            gatewayGraphQlUrl: 'http://gw/graphql',
            appRole: ManoRole.provider,
          ),
        ),
        offlineMarketplaceProvider.overrideWithValue(true),
      ],
    );
    expect(
      c.read(workerReferralRedeemerProvider),
      isA<MockWorkerReferralRedeemer>(),
    );
  });

  test('online, redemption goes to the gateway', () {
    final c = ProviderContainer.test(
      overrides: [
        manoConfigProvider.overrideWithValue(
          const ManoConfig(
            gatewayGraphQlUrl: 'http://gw/graphql',
            appRole: ManoRole.provider,
          ),
        ),
      ],
    );
    expect(
      c.read(workerReferralRedeemerProvider),
      isA<GatewayWorkerReferralRedeemer>(),
    );
  });
}
