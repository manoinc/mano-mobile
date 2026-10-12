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

  group('ReferralProgram', () {
    test('progress is capped at the goal', () {
      const program = ReferralProgram(
        code: 'MANO-1',
        invited: 7,
        goal: 5,
        rewardCoins: 10,
      );
      expect(program.progress, 1.0);
      expect(program.completed, isTrue);
    });

    test('progress is the share invited', () {
      const program = ReferralProgram(
        code: 'MANO-1',
        invited: 2,
        goal: 5,
        rewardCoins: 10,
      );
      expect(program.progress, closeTo(0.4, 1e-9));
      expect(program.completed, isFalse);
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
