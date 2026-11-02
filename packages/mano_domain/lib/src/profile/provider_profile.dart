import '../shared/party.dart';

/// A professional as they see (and are seen on) their own profile.
final class ProviderProfile {
  const ProviderProfile({
    required this.party,
    required this.bio,
    required this.zones,
    required this.yearsExperience,
    required this.verified,
  });

  final Party party;
  final String bio;
  final List<String> zones;
  final int yearsExperience;
  final bool verified;

  String get firstName => party.displayName.trim().split(' ').first;
}

/// How the professional has performed so far.
final class ProviderStats {
  const ProviderStats({
    required this.rating,
    required this.reviewCount,
    required this.jobsCompleted,
    required this.responseRatePct,
    required this.completionRatePct,
  });

  final double rating;
  final int reviewCount;
  final int jobsCompleted;
  final int responseRatePct;
  final int completionRatePct;
}

/// Invite-a-colleague progress and the code to share.
final class ReferralProgram {
  const ReferralProgram({
    required this.code,
    required this.invited,
    required this.goal,
    required this.rewardCoins,
  });

  final String code;
  final int invited;
  final int goal;
  final int rewardCoins;

  double get progress => goal <= 0 ? 1 : (invited / goal).clamp(0.0, 1.0);
  bool get completed => invited >= goal;
}
