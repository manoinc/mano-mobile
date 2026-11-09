import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('nothing sent yet means every document is missing', () {
    const status = IdentityCheckInProgress(submitted: {});

    expect(status.missing, IdentityDocumentKind.values.toSet());
    expect(status.isComplete, isFalse);
  });

  test('both sides of the cédula and a selfie complete it', () {
    final status = IdentityCheckInProgress(
      submitted: IdentityDocumentKind.values.toSet(),
    );

    expect(status.missing, isEmpty);
    expect(status.isComplete, isTrue);
  });

  test('the selfie is the last step', () {
    expect(IdentityDocumentKind.values.last, IdentityDocumentKind.selfie);
  });

  test('a rejection carries the reason to show', () {
    const status = IdentityCheckRejected(reason: 'La foto está borrosa');

    expect(status.reason, 'La foto está borrosa');
    expect(status.canRetry, isTrue);
  });
}
