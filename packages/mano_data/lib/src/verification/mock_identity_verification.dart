import 'package:mano_domain/mano_domain.dart';

/// In-memory identity check; stands in until a vendor adapter exists.
final class MockIdentityVerification implements IdentityVerificationPort {
  MockIdentityVerification({this.approveOnFinish = false});

  /// Answers a finished check with approval at once, to exercise the gate.
  final bool approveOnFinish;

  final Set<IdentityDocumentKind> _submitted = {};
  bool _sent = false;

  IdentityCheckStatus get _status => !_sent
      ? IdentityCheckInProgress(submitted: {..._submitted})
      : approveOnFinish
      ? const IdentityCheckApproved()
      : const IdentityCheckPending();

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> status() async =>
      Ok(_status);

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> submit(
    IdentityDocumentKind kind,
    PickedImage image,
  ) async {
    if (!image.isSupported) return const Err(DataRejected(reason: 'type'));
    _submitted.add(kind);
    return Ok(_status);
  }

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> finish() async {
    if (_submitted.length < IdentityDocumentKind.values.length) {
      return const Err(DataRejected(reason: 'missing documents'));
    }
    _sent = true;
    return Ok(_status);
  }
}
