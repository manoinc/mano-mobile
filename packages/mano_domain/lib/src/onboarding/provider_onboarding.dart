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
    this.categories = const [],
    this.yearsExperience = 0,
    this.bio = '',
    this.documentPaths = const [],
  });

  final String displayName;
  final String phone;
  final String workZone;

  /// Canonical service category ids the professional offers.
  final List<String> categories;
  final int yearsExperience;
  final String bio;

  /// Local files to upload: ID and optional certificates.
  final List<String> documentPaths;

  @override
  bool operator ==(Object other) =>
      other is WorkerProfileDraft &&
      other.displayName == displayName &&
      other.phone == phone &&
      other.workZone == workZone &&
      _listEquals(other.categories, categories) &&
      other.yearsExperience == yearsExperience &&
      other.bio == bio &&
      _listEquals(other.documentPaths, documentPaths);

  @override
  int get hashCode => Object.hash(
    displayName,
    phone,
    workZone,
    Object.hashAll(categories),
    yearsExperience,
    bio,
    Object.hashAll(documentPaths),
  );

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
  Future<Result<VerificationStatus, DataFailure>> submit(
    WorkerProfileDraft draft,
  );
}
