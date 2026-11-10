import 'package:mano_session/mano_session.dart';

/// A profile shaped like the live gateway's: no bio, years, response rate or reward.
final class LiveShapedProfile implements ProviderProfileRepository {
  LiveShapedProfile({
    this.stand = const ProviderStats(
      rating: 4.8,
      reviewCount: 12,
      jobsCompleted: 3,
      completionRatePct: 75,
    ),
    this.displayName = 'Luisa Pérez',
    this.phone = '3001112233',
  });

  final ProviderStats stand;
  final String displayName;
  final String phone;

  @override
  Future<ProviderProfile> profile() async => ProviderProfile(
    party: Party(id: 'w1', displayName: displayName, photoUrl: ''),
    bio: '',
    zones: ['Chapinero'],
    yearsExperience: 0,
    verified: false,
    phone: phone,
    email: 'luisa@mano.co',
  );

  @override
  Future<ProviderStats> stats() async => stand;

  @override
  Future<List<Review>> reviews() async => const [];

  @override
  Future<ReferralProgram> referral() async =>
      const ReferralProgram(code: 'RP-1a2b3c4d');
}
