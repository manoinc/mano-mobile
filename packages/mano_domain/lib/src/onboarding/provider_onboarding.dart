import '../result.dart';
import '../shared/data_failure.dart';

enum VerificationStatus {
  notSubmitted,
  pending,
  underReview,
  approved,
  rejected,
  informationRequired,
}

/// What a professional fills in before staff review.
final class WorkerProfileDraft {
  const WorkerProfileDraft({
    required this.displayName,
    required this.phone,
    required this.workZone,
    this.documentPaths = const [],
  });

  final String displayName;
  final String phone;
  final String workZone;

  /// Local files to upload: ID and optional certificates.
  final List<String> documentPaths;

  @override
  bool operator ==(Object other) =>
      other is WorkerProfileDraft &&
      other.displayName == displayName &&
      other.phone == phone &&
      other.workZone == workZone &&
      _listEquals(other.documentPaths, documentPaths);

  @override
  int get hashCode =>
      Object.hash(displayName, phone, workZone, Object.hashAll(documentPaths));

  @override
  String toString() => 'WorkerProfileDraft($displayName, $workZone)';
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

abstract interface class ProviderOnboardingRepository {
  Future<VerificationStatus> status();

  /// Sends profile and documents for staff review.
  Future<Result<VerificationStatus, DataFailure>> submit(WorkerProfileDraft draft);
}
