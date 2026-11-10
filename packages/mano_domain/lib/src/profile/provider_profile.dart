import '../shared/party.dart';

/// A professional as they see (and are seen on) their own profile.
final class ProviderProfile {
  const ProviderProfile({
    required this.party,
    required this.bio,
    required this.zones,
    required this.yearsExperience,
    required this.verified,
    this.skills = const [],
    this.portfolioUrls = const [],
    this.phone = '',
    this.email = '',
  });

  final Party party;
  final String bio;
  final List<String> zones;
  final int yearsExperience;
  final bool verified;

  /// Service category ids (`ServiceCategories`).
  final List<String> skills;

  /// Photos of past work, in order.
  final List<String> portfolioUrls;

  final String phone;
  final String email;

  String get firstName => party.displayName.trim().split(' ').first;
}

/// How the professional has performed so far; null means not served yet.
final class ProviderStats {
  const ProviderStats({
    this.rating,
    this.reviewCount = 0,
    this.jobsCompleted,
    this.responseRatePct,
    this.completionRatePct,
  });

  final double? rating;
  final int reviewCount;
  final int? jobsCompleted;
  final int? responseRatePct;
  final int? completionRatePct;

  /// A 0..1 rate as a whole percent.
  static int? percentOf(double? rate) =>
      rate == null ? null : (rate * 100).round();
}

/// The code to share, who joined with it, and what each verified colleague earns.
final class ReferralProgram {
  const ReferralProgram({
    required this.code,
    this.invited = 0,
    this.verified = 0,
    this.coinsPerColleague,
  });

  final String code;

  /// Colleagues who signed up with [code] (gateway `referralsCount`).
  final int invited;

  /// Of those, the ones whose identity is verified (`verifiedReferralsCount`).
  final int verified;

  /// Coins per verified colleague (`referralReward`); null where no reward runs.
  final int? coinsPerColleague;
}
