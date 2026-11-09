import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('EarningsSummary', () {
    test('total is the sum of the buckets', () {
      final summary = EarningsSummary(
        period: EarningsPeriod.week,
        buckets: [
          EarningsBucket(start: DateTime(2026, 10, 5), amountCop: 100000),
          EarningsBucket(start: DateTime(2026, 10, 6), amountCop: 50000),
        ],
        recent: const [],
      );
      expect(summary.totalCop, 150000);
    });

    test('an empty summary totals zero', () {
      const summary = EarningsSummary(
        period: EarningsPeriod.month,
        buckets: [],
        recent: [],
      );
      expect(summary.totalCop, 0);
    });
  });

  group('ReferralReward', () {
    test('progress is capped at the goal', () {
      const reward = ReferralReward(invited: 7, goal: 5, coins: 10);
      expect(reward.progress, 1.0);
      expect(reward.completed, isTrue);
    });

    test('progress is the share invited', () {
      const reward = ReferralReward(invited: 2, goal: 5, coins: 10);
      expect(reward.progress, closeTo(0.4, 1e-9));
      expect(reward.completed, isFalse);
    });

    test('a program without a reward only carries its code', () {
      const program = ReferralProgram(code: 'MANO-1');
      expect(program.reward, isNull);
    });
  });

  group('ProviderStats', () {
    test('completion percent rounds the served rate', () {
      expect(ProviderStats.percentOf(0.756), 76);
      expect(ProviderStats.percentOf(null), isNull);
    });

    test('what the backend does not serve stays unknown', () {
      const stats = ProviderStats(reviewCount: 0);
      expect(stats.rating, isNull);
      expect(stats.jobsCompleted, isNull);
      expect(stats.responseRatePct, isNull);
      expect(stats.completionRatePct, isNull);
    });
  });

  test('firstName is the first word of the display name', () {
    const profile = ProviderProfile(
      party: Party(id: 'p', displayName: 'Carlos Mejía', photoUrl: 'u'),
      bio: '',
      zones: [],
      yearsExperience: 1,
      verified: true,
    );
    expect(profile.firstName, 'Carlos');
  });
}
