import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer.test(
      overrides: [
        manoConfigProvider.overrideWithValue(
          const ManoConfig(
            gatewayGraphQlUrl: 'http://localhost/graphql',
            appRole: ManoRole.requester,
          ),
        ),
        offlineMarketplaceProvider.overrideWithValue(true),
      ],
    );
  });

  test('the profile, stats and referral resolve from the mock', () async {
    expect(
      (await container.read(providerProfileProvider.future)).firstName,
      isNotEmpty,
    );
    expect(
      (await container.read(providerStatsProvider.future)).rating,
      greaterThan(0),
    );
    expect(
      (await container.read(referralProvider.future)).coinsPerColleague,
      10,
    );
  });

  test('online, profiles, editing and referral codes go to the gateway', () {
    final live = ProviderContainer.test(
      overrides: [
        manoConfigProvider.overrideWithValue(
          const ManoConfig(
            gatewayGraphQlUrl: 'http://localhost/graphql',
            appRole: ManoRole.provider,
          ),
        ),
      ],
    );
    final repo = live.read(providerProfileRepositoryProvider);
    expect(repo, isA<GatewayProviderProfileRepository>());
    expect(live.read(providerProfileEditorProvider), same(repo));
    expect(live.read(referralLinkerProvider), isA<GatewayReferralLinker>());
    expect(
      live.read(clientProfileRepositoryProvider),
      isA<GatewayClientProfileRepository>(),
    );
  });

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
