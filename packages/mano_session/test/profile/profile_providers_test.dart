import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer.test(
      overrides: [
        manoConfigProvider.overrideWithValue(
          const ManoConfig(gatewayGraphQlUrl: 'http://localhost/graphql'),
        ),
      ],
    );
  });

  test(
    'the profile, stats, reviews and referral resolve from the mock',
    () async {
      expect(
        (await container.read(providerProfileProvider.future)).firstName,
        isNotEmpty,
      );
      expect(
        (await container.read(providerStatsProvider.future)).rating,
        greaterThan(0),
      );
      expect(await container.read(providerReviewsProvider.future), isNotEmpty);
      expect((await container.read(referralProvider.future)).rewardCoins, 10);
    },
  );

  test('earnings are read per period', () async {
    final week = await container.read(
      earningsProvider(EarningsPeriod.week).future,
    );
    final month = await container.read(
      earningsProvider(EarningsPeriod.month).future,
    );
    expect(week.period, EarningsPeriod.week);
    expect(month.totalCop, greaterThan(week.totalCop));
  });
}
