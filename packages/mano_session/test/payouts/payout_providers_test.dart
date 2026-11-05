import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  const draft = PayoutAccountDraft(
    method: PayoutMethod.nequi,
    phone: '300 123 4567',
    holderName: 'Andrés Castro',
    holderEmail: 'andres@mano.test',
    legalId: '1020304050',
  );

  late ProviderContainer container;

  setUp(
    () => container = ProviderContainer.test(
      overrides: [offlineMarketplaceProvider.overrideWithValue(true)],
    ),
  );

  PayoutActions actions() => container.read(payoutActionsProvider.notifier);

  test('no account until one is registered', () async {
    expect(await container.read(payoutAccountProvider.future), isNull);

    final result = await actions().register(draft);

    expect(result.isOk, isTrue);
    final account = await container.read(payoutAccountProvider.future);
    expect(account!.destination, const NequiDestination(phone: '3001234567'));
    expect(account.holder.name, 'Andrés Castro');
  });

  test('an invalid draft is refused before reaching the port', () async {
    final result = await actions().register(draft.copyWith(phone: '123'));
    expect(result.failureOrNull, isA<DataRejected>());
    expect(await container.read(payoutAccountProvider.future), isNull);
  });

  test('removing the account leaves none', () async {
    final account = (await actions().register(draft)).valueOrNull!;
    await container.read(payoutAccountProvider.future);

    expect((await actions().remove(account.id)).isOk, isTrue);
    expect(await container.read(payoutAccountProvider.future), isNull);
  });

  test('payout banks come from the port', () async {
    final banks = await container.read(payoutBanksProvider.future);
    expect(banks, contains(const Bank(code: '1007', name: 'Bancolombia')));
  });

  test('live, the accounts go through the gateway', () {
    final live = ProviderContainer.test(
      overrides: [
        manoConfigProvider.overrideWithValue(
          const ManoConfig(gatewayGraphQlUrl: 'http://gw', appRole: 'provider'),
        ),
      ],
    );
    expect(live.read(payoutAccountsProvider), isA<GatewayPayoutAccounts>());
  });
}
