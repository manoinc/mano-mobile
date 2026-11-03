import 'package:mano_domain/mano_domain.dart';

import '../mock/mock_fixtures.dart';

/// In-memory profile of the first mock professional; edits are kept in memory.
final class MockProviderProfileRepository
    implements ProviderProfileRepository, ProviderProfileEditor {
  MockProviderProfileRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  ProviderProfile _profile = ProviderProfile(
    party: mockProviders.first,
    bio:
        'Más de ocho años cuidando casas en Bogotá. Puntual, ordenado y '
        'siempre con los materiales listos.',
    zones: const ['Chapinero', 'Usaquén', 'Teusaquillo'],
    yearsExperience: 8,
    verified: true,
    skills: const ['cleaning', 'painting', 'plumbing'],
    portfolioUrls: [
      mockPhoto('1581578731548-c64695cc6952'),
      mockPhoto('1562259949-e8e7689d7828'),
    ],
  );

  @override
  Future<ProviderProfile> profile() async => _profile;

  @override
  Future<Result<ProviderProfile, DataFailure>> save(
    ProviderProfileDraft draft,
  ) async {
    if (!draft.isValid) {
      return Err(DataRejected(reason: '${draft.problems}'));
    }
    _profile = ProviderProfile(
      party: Party(
        id: _profile.party.id,
        displayName: draft.displayName.trim(),
        photoUrl: draft.photoUrl,
      ),
      bio: draft.bio.trim(),
      zones: draft.zones,
      yearsExperience: _profile.yearsExperience,
      verified: _profile.verified,
      skills: draft.skills,
      portfolioUrls: draft.portfolioUrls,
    );
    return Ok(_profile);
  }

  @override
  Future<ProviderStats> stats() async => const ProviderStats(
    rating: 4.9,
    reviewCount: 32,
    jobsCompleted: 118,
    responseRatePct: 96,
    completionRatePct: 98,
  );

  @override
  Future<List<Review>> reviews() async {
    final n = _now();
    final today = DateTime(n.year, n.month, n.day);
    Review review(String id, Party who, int stars, int ago, String text) =>
        Review(
          id: id,
          reviewer: who,
          stars: stars,
          date: today.subtract(Duration(days: ago)),
          text: text,
        );
    return [
      review(
        'r1',
        mockClient,
        5,
        2,
        'Llegó a la hora y dejó todo impecable. Lo recomiendo.',
      ),
      review(
        'r2',
        const Party(
          id: 'client-2',
          displayName: 'Camilo Rojas',
          photoUrl: 'https://randomuser.me/api/portraits/men/75.jpg',
        ),
        5,
        9,
        'Resolvió la fuga en una hora y explicó todo con paciencia.',
      ),
      review(
        'r3',
        const Party(
          id: 'client-3',
          displayName: 'Marta Díaz',
          photoUrl: 'https://randomuser.me/api/portraits/women/21.jpg',
        ),
        4,
        21,
        'Muy buen trabajo, solo se demoró un poco en llegar.',
      ),
      review(
        'r4',
        const Party(
          id: 'client-4',
          displayName: 'Julián Mora',
          photoUrl: 'https://randomuser.me/api/portraits/men/46.jpg',
        ),
        5,
        34,
        'Excelente trato y muy limpio. Volveré a contratarlo.',
      ),
    ];
  }

  @override
  Future<ReferralProgram> referral() async => const ReferralProgram(
    code: 'ANDRES-M4N0',
    invited: 2,
    goal: 5,
    rewardCoins: 10,
  );
}
