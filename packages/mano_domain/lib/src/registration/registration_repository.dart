import '../result.dart';
import 'registration_draft.dart';
import 'registration_failure.dart';

/// The port through which a finished draft becomes an account.
///
/// Nothing here says where it goes. The adapter that answers this is the whole
/// footprint of that decision, exactly as [SessionRepository] is for sign-in.
abstract interface class RegistrationRepository {
  /// Submits a completed draft.
  ///
  /// Returns [Ok] when the draft has been accepted -- which, until a backend
  /// exists, means accepted on this device and nowhere else.
  Future<Result<void, RegistrationFailure>> submit(RegistrationDraft draft);
}
