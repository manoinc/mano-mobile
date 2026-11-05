import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

List<String> _ids(List<ServiceRequest> requests) => [
  for (final r in requests) r.id,
];

Future<List<String>> _idsIn(
  ProviderContainer c,
  ServiceRequestStatus status,
) async => _ids(await c.read(requestsByStatusProvider(status).future));

Future<ServiceRequest> _lead(ProviderContainer c, String id) async =>
    (await c.read(myServiceRequestsProvider.future))
        .firstWhere((r) => r.id == id);

// The coupled offline mocks, so accepting a request schedules a job.
ProviderContainer _offline() => ProviderContainer.test(
  overrides: [offlineMarketplaceProvider.overrideWithValue(true)],
);

void main() {
  group('respond (pay per lead)', () {
    test('accepts the lead and spends its cost in coins', () async {
      final c = _offline();
      final lead = await _lead(c, 'request-2');
      final before = (await c.read(walletProvider.future)).balance;

      final result = await c
          .read(requestActionsProvider.notifier)
          .respond(lead);

      expect(result.valueOrNull?.status, ServiceRequestStatus.accepted);
      expect(
        (await c.read(walletProvider.future)).balance,
        before - lead.leadCost,
      );
      final history = await c.read(walletHistoryProvider.future);
      expect(history.first.requestId, 'request-2');
      expect(history.first.kind, CoinTransactionKind.leadSpend);
    });

    test('with too few coins it fails and leaves the lead pending', () async {
      final c = _offline();
      final lead = await _lead(c, 'request-2');
      final wallet = c.read(walletRepositoryProvider);
      await wallet.spendForLead(
        'x',
        (await wallet.wallet()).balance,
        label: 'x',
      );

      final result = await c
          .read(requestActionsProvider.notifier)
          .respond(lead);

      expect(result.failureOrNull, isA<InsufficientCoins>());
      expect(
        await _idsIn(c, ServiceRequestStatus.pending),
        contains('request-2'),
      );
    });

    test('refunds the coins when the accept itself fails', () async {
      final c = _offline();
      final lead = await _lead(c, 'request-2');
      await c.read(requestActionsProvider.notifier).accept('request-2');
      final before = (await c.read(walletProvider.future)).balance;

      // Already answered, so the repository refuses it.
      final result = await c
          .read(requestActionsProvider.notifier)
          .respond(lead);

      expect(result.isErr, isTrue);
      expect((await c.read(walletProvider.future)).balance, before);
    });
  });

  group('wallet wiring', () {
    test('offline runs on the mock, live on the gateway', () {
      expect(
        _offline().read(walletRepositoryProvider),
        isA<MockWalletRepository>(),
      );
      final live = ProviderContainer.test(
        overrides: [
          manoConfigProvider.overrideWithValue(
            const ManoConfig(
              gatewayGraphQlUrl: 'http://gw',
              appRole: 'provider',
            ),
          ),
        ],
      );
      expect(
        live.read(walletRepositoryProvider),
        isA<GatewayWalletRepository>(),
      );
    });

    test('checkout terms and PSE banks are read from the port', () async {
      final c = _offline();
      expect(await c.read(checkoutTermsProvider.future), isNotEmpty);
      expect(await c.read(pseBanksProvider.future), isNotEmpty);
    });
  });

  group('RequestActions', () {
    test('accept moves the request to accepted and schedules a job', () async {
      final c = _offline();
      await _idsIn(c, ServiceRequestStatus.pending);
      final jobsBefore = await c.read(myJobsProvider.future);

      final result = await c
          .read(requestActionsProvider.notifier)
          .accept('request-1');

      expect(result.valueOrNull?.status, ServiceRequestStatus.accepted);
      expect(
        await _idsIn(c, ServiceRequestStatus.pending),
        isNot(contains('request-1')),
      );
      expect(
        await _idsIn(c, ServiceRequestStatus.accepted),
        contains('request-1'),
      );
      final jobs = await c.read(myJobsProvider.future);
      expect(jobs.length, jobsBefore.length + 1);
    });

    test('reject stores the reason and refreshes the lists', () async {
      final c = _offline();
      await _idsIn(c, ServiceRequestStatus.rejected);

      final result = await c
          .read(requestActionsProvider.notifier)
          .reject('request-2', reason: 'Sin cupo');

      expect(result.valueOrNull?.rejectionReason, 'Sin cupo');
      expect(
        await _idsIn(c, ServiceRequestStatus.rejected),
        contains('request-2'),
      );
    });

    test(
      'accept refetches jobs, which the backend creates on its side',
      () async {
        // Uncoupled stores, like the gateway: the job list changes only by refetching.
        final c = ProviderContainer.test(
          overrides: [
            serviceRequestRepositoryProvider.overrideWithValue(
              MockServiceRequestRepository(),
            ),
            jobRepositoryProvider.overrideWithValue(MockJobRepository()),
          ],
        );
        var jobBuilds = 0;
        c.listen(myJobsProvider, (_, _) => jobBuilds++);
        await c.read(myJobsProvider.future);
        final before = jobBuilds;

        final pending = (await c.read(
          requestsByStatusProvider(ServiceRequestStatus.pending).future,
        )).first;
        await c.read(requestActionsProvider.notifier).accept(pending.id);
        await c.read(myJobsProvider.future);

        expect(jobBuilds, greaterThan(before));
      },
    );

    test('a failed accept reports the failure and leaves jobs alone', () async {
      final c = _offline();
      var jobBuilds = 0;
      c.listen(myJobsProvider, (_, _) => jobBuilds++);
      await c.read(myJobsProvider.future);
      final before = jobBuilds;

      final result = await c
          .read(requestActionsProvider.notifier)
          .accept('request-3');

      expect(result.failureOrNull, isA<DataRejected>());
      expect(jobBuilds, before);
    });
  });
}
