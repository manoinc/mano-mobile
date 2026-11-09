import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  test('the new ports have offline adapters until their streams wire them', () {
    // The identity mock reads the config for its debug approval switch.
    final container = ProviderContainer(
      overrides: [
        manoConfigProvider.overrideWithValue(
          const ManoConfig(gatewayGraphQlUrl: 'http://gw', appRole: 'provider'),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(jobPaymentRepositoryProvider),
      isA<JobPaymentRepository>(),
    );
    expect(
      container.read(identityVerificationProvider),
      isA<IdentityVerificationPort>(),
    );
    expect(container.read(referralLinkerProvider), isA<ReferralLinker>());
  });

  test('an unpaid job reads as no payment', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(jobPaymentProvider('job-1').future), isNull);
  });
}
