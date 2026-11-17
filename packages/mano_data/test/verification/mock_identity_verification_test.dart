import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

void main() {
  test('starts not started', () async {
    final port = MockIdentityVerification();

    expect((await port.status()).valueOrNull, isA<IdentityCheckNotStarted>());
  });

  test('a verified check goes to review', () async {
    final port = MockIdentityVerification();

    expect((await port.verify()).valueOrNull, isA<IdentityCheckPending>());
    expect((await port.status()).valueOrNull, isA<IdentityCheckPending>());
  });

  test('set to approve, a verified check comes back approved', () async {
    final port = MockIdentityVerification(approveOnVerify: true);

    expect((await port.verify()).valueOrNull, isA<IdentityCheckApproved>());
    expect((await port.status()).valueOrNull, isA<IdentityCheckApproved>());
  });
}
