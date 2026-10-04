import 'package:mano_domain/mano_domain.dart';

/// In-memory [ProviderOnboardingRepository]; there is no verification backend yet.
final class MockProviderOnboardingRepository
    implements ProviderOnboardingRepository {
  VerificationStatus _status = VerificationStatus.notSubmitted;

  @override
  Future<VerificationStatus> status() async => _status;

  @override
  Future<Result<VerificationStatus, DataFailure>> submit(
    WorkerProfileDraft draft,
  ) async {
    if (draft.displayName.trim().isEmpty || draft.documentPaths.isEmpty) {
      return const Err(DataRejected(reason: 'name and documents are required'));
    }
    return Ok(_status = VerificationStatus.pending);
  }
}
