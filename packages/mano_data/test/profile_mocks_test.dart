import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_data/src/mock/mock_fixtures.dart';
import 'package:mano_domain/mano_domain.dart';

void main() {
  final now = DateTime(2026, 10, 14, 10);

  group('MockEarningsRepository', () {
    final repo = MockEarningsRepository(now: () => now);

    test('week has seven daily buckets ending today', () async {
      final week = await repo.summary(EarningsPeriod.week);
      expect(week.buckets, hasLength(7));
      expect(week.buckets.last.start, DateTime(2026, 10, 14));
      expect(week.totalCop, greaterThan(0));
    });

    test(
      'month has four weekly buckets and earns more than the week',
      () async {
        final week = await repo.summary(EarningsPeriod.week);
        final month = await repo.summary(EarningsPeriod.month);
        expect(month.buckets, hasLength(4));
        expect(month.totalCop, greaterThan(week.totalCop));
      },
    );

    test('lists paid jobs newest first with a payout ahead', () async {
      final week = await repo.summary(EarningsPeriod.week);
      final dates = week.recent.map((j) => j.paidAt).toList();
      expect(dates, [...dates]..sort((a, b) => b.compareTo(a)));
      expect(week.nextPayout!.date.isAfter(now), isTrue);
    });
  });

  group('MockProviderProfileRepository', () {
    final repo = MockProviderProfileRepository(now: () => now);

    test('the profile is the first mock professional', () async {
      final profile = await repo.profile();
      expect(profile.party, mockProviders.first);
      expect(profile.verified, isTrue);
    });

    test('reviews are newest first and stats agree on the count', () async {
      final reviews = await repo.reviews();
      final stats = await repo.stats();
      expect(reviews, isNotEmpty);
      expect(reviews.first.date.isAfter(reviews.last.date), isTrue);
      expect(stats.reviewCount, greaterThanOrEqualTo(reviews.length));
    });

    test('referral offers coins and a code', () async {
      final referral = await repo.referral();
      expect(referral.code, isNotEmpty);
      expect(referral.reward!.coins, 10);
      expect(referral.reward!.invited, lessThan(referral.reward!.goal));
    });

    test('a seeded profile replaces the fixture', () async {
      const blank = ProviderProfile(
        party: Party(id: '', displayName: '', photoUrl: ''),
        bio: '',
        zones: [],
        yearsExperience: 0,
        verified: false,
      );
      final seeded = MockProviderProfileRepository(initial: blank);
      expect((await seeded.profile()).party.displayName, isEmpty);
    });
  });
}
