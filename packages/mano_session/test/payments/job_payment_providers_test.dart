import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  test('the new ports have offline adapters until their streams wire them', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(jobPaymentRepositoryProvider),
      isA<JobPaymentRepository>(),
    );
    expect(
      container.read(identityVerificationProvider),
      isA<IdentityVerificationPort>(),
    );
  });

  test('an unpaid job reads as no payment', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(jobPaymentProvider('job-1').future), isNull);
  });
}
