import 'package:mano_domain/mano_domain.dart';

/// In-memory [ClientProfileRepository], seeded with what sign-up knew.
final class MockClientProfileRepository implements ClientProfileRepository {
  MockClientProfileRepository({ClientProfile initial = const ClientProfile()})
    : _profile = initial;

  ClientProfile _profile;

  @override
  Future<ClientProfile> profile() async => _profile;

  @override
  Future<Result<ClientProfile, DataFailure>> update(
    ClientProfile profile,
  ) async {
    if (profile.problems.isNotEmpty) {
      return Err(DataRejected(reason: '${profile.problems}'));
    }
    _profile = profile;
    return Ok(profile);
  }

  @override
  Future<Result<ClientProfile, DataFailure>> updatePhoto(
    MediaAttachment photo,
  ) async {
    _profile = _profile.copyWith(photoUrl: () => photo.url);
    return Ok(_profile);
  }
}
