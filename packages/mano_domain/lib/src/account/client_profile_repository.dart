import '../result.dart';
import '../shared/data_failure.dart';
import 'client_profile.dart';

/// The signed-in Solicitante's profile (gateway: `updateClientProfile`).
abstract interface class ClientProfileRepository {
  Future<ClientProfile> profile();

  /// Saves every field; refused while [ClientProfile.problems] is not empty.
  Future<Result<ClientProfile, DataFailure>> update(ClientProfile profile);

  /// Saves only the photo, from a finished avatar upload.
  Future<Result<ClientProfile, DataFailure>> updatePhoto(String photoUrl);
}
