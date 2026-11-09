import '../media/picked_image.dart';
import '../result.dart';
import '../shared/data_failure.dart';
import 'identity_document_kind.dart';
import 'identity_check_status.dart';

/// Checks that a person is who they say; no vendor is named on purpose.
abstract interface class IdentityVerificationPort {
  Future<Result<IdentityCheckStatus, DataFailure>> status();

  /// Replaces any earlier photo of the same [kind].
  Future<Result<IdentityCheckStatus, DataFailure>> submit(
    IdentityDocumentKind kind,
    PickedImage image,
  );

  /// Sends everything for review; refused while documents are missing.
  Future<Result<IdentityCheckStatus, DataFailure>> finish();
}
