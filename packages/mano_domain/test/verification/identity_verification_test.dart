import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('a rejection carries the reason to show and whether to try again', () {
    const status = IdentityCheckRejected(
      reason: 'La foto está borrosa',
      canRetry: true,
    );

    expect(status.reason, 'La foto está borrosa');
    expect(status.canRetry, isTrue);
  });

  test('a final rejection offers no retry', () {
    const status = IdentityCheckRejected(reason: 'No', canRetry: false);

    expect(status.canRetry, isFalse);
  });

  test('a check not started yet is its own status', () {
    expect(const IdentityCheckNotStarted(), isA<IdentityCheckStatus>());
  });
}
