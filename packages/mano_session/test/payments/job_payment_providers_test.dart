import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

ProviderContainer _offline() => ProviderContainer.test(
  overrides: [offlineMarketplaceProvider.overrideWithValue(true)],
);

void main() {
  test('job payments run on the mock offline, on the gateway live', () {
    expect(
      _offline().read(jobPaymentRepositoryProvider),
      isA<MockJobPaymentRepository>(),
    );
    final live = ProviderContainer.test(
      overrides: [
        manoConfigProvider.overrideWithValue(
          const ManoConfig(
            gatewayGraphQlUrl: 'http://gw',
            appRole: 'requester',
          ),
        ),
      ],
    );
    expect(
      live.read(jobPaymentRepositoryProvider),
      isA<GatewayJobPaymentRepository>(),
    );
  });

  test('the other new ports have offline adapters', () {
    final container = _offline();
    expect(
      container.read(identityVerificationProvider),
      isA<IdentityVerificationPort>(),
    );
    expect(container.read(referralLinkerProvider), isA<ReferralLinker>());
  });

  test('an unpaid job reads as no payment', () async {
    expect(await _offline().read(jobPaymentProvider('job-1').future), isNull);
  });

  test('checkout terms and PSE banks come from the job payment port', () async {
    final c = _offline();
    expect(await c.read(jobCheckoutTermsProvider.future), isNotEmpty);
    expect(await c.read(jobPseBanksProvider.future), isNotEmpty);
  });
}
