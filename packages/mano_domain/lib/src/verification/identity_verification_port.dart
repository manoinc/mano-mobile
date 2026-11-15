import '../result.dart';
import '../shared/data_failure.dart';
import 'identity_check_status.dart';

/// Checks that a person is who they say; no vendor is named on purpose.
abstract interface class IdentityVerificationPort {
  Future<Result<IdentityCheckStatus, DataFailure>> status();

  /// Runs the checker's own capture flow, then reports where things stand.
  Future<Result<IdentityCheckStatus, DataFailure>> verify();
}
