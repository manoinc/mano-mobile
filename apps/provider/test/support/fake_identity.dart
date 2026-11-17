import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mano_session/mano_session.dart';

/// Reports [reported]; verify answers [verified], pending by default.
final class FakeIdentityVerification implements IdentityVerificationPort {
  FakeIdentityVerification([
    this.reported = const IdentityCheckNotStarted(),
    this.verified = const Ok(IdentityCheckPending()),
  ]);

  IdentityCheckStatus reported;
  Result<IdentityCheckStatus, DataFailure> verified;
  var verifies = 0;

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> status() async =>
      Ok(reported);

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> verify() async {
    verifies++;
    if (verified case Ok(:final value)) reported = value;
    return verified;
  }
}

/// A pro whose identity check came back approved, so no gate stops them.
Override verifiedIdentity() => identityVerificationProvider.overrideWithValue(
  FakeIdentityVerification(const IdentityCheckApproved()),
);
