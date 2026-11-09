import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mano_session/mano_session.dart';

/// Reports [reported] when set; otherwise collects photos like the mock.
final class FakeIdentityVerification implements IdentityVerificationPort {
  FakeIdentityVerification([this.reported]);

  IdentityCheckStatus? reported;
  final _kinds = <IdentityDocumentKind>{};

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> status() async =>
      Ok(reported ?? IdentityCheckInProgress(submitted: {..._kinds}));

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> submit(
    IdentityDocumentKind kind,
    PickedImage image,
  ) async {
    _kinds.add(kind);
    return Ok(IdentityCheckInProgress(submitted: {..._kinds}));
  }

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> finish() async =>
      Ok(reported = const IdentityCheckPending());
}

/// A pro whose identity check came back approved, so no gate stops them.
Override verifiedIdentity() => identityVerificationProvider.overrideWithValue(
  FakeIdentityVerification(const IdentityCheckApproved()),
);
