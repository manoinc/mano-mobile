import '../shared/party.dart';

/// A professional as a requester sees them before hiring.
final class PublicProviderProfile {
  const PublicProviderProfile({
    required this.party,
    required this.bio,
    required this.verified,
    this.skills = const [],
    this.portfolioUrls = const [],
  });

  final Party party;
  final String bio;
  final bool verified;

  /// Service categories, as shown on chips.
  final List<String> skills;
  final List<String> portfolioUrls;
}
