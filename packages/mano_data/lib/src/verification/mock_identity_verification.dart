import 'package:mano_domain/mano_domain.dart';

/// In-memory identity check, for tests, Widgetbook and runs without auth.
final class MockIdentityVerification implements IdentityVerificationPort {
  MockIdentityVerification({this.approveOnVerify = false});

  /// Answers a verified check with approval at once, to exercise the gate.
  final bool approveOnVerify;

  IdentityCheckStatus _status = const IdentityCheckNotStarted();

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> status() async =>
      Ok(_status);

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> verify() async {
    _status = approveOnVerify
        ? const IdentityCheckApproved()
        : const IdentityCheckPending();
    return Ok(_status);
  }
}
