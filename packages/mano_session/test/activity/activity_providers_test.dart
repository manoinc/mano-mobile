import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

final _now = DateTime(2026, 10, 4, 12);

ProviderContainer _container() => ProviderContainer.test(
  overrides: [
    jobRepositoryProvider.overrideWithValue(MockJobRepository(now: () => _now)),
    serviceRequestRepositoryProvider.overrideWithValue(
      MockServiceRequestRepository(now: () => _now),
    ),
  ],
);

List<String> _ids(Iterable<Object> items) => [
  for (final item in items)
    switch (item) {
      Job(:final id) => id,
      ServiceRequest(:final id) => id,
      _ => '$item',
    },
];

void main() {
  group('jobProvider', () {
    test('reads one job by id', () async {
      final job = await _container().read(jobProvider('job-1').future);
      expect(job?.id, 'job-1');
    });

    test('is null for an unknown id', () async {
      expect(await _container().read(jobProvider('nope').future), isNull);
    });
  });

  group('selectors', () {
    test('jobsByStatusProvider keeps only jobs in that status', () async {
      final c = _container();
      final scheduled = await c.read(
        jobsByStatusProvider(JobStatus.scheduled).future,
      );
      expect(_ids(scheduled), ['job-1', 'job-2']);
    });

    test(
      'requestsByStatusProvider keeps only requests in that status',
      () async {
        final c = _container();
        final pending = await c.read(
          requestsByStatusProvider(ServiceRequestStatus.pending).future,
        );
        expect(_ids(pending), [
          'request-1',
          'request-2',
          'request-6',
          'request-7',
          'request-8',
        ]);
      },
    );
  });

  group('ActivityActions', () {
    test('cancelJob cancels and refreshes every job read', () async {
      final c = _container();
      await c.read(jobsByStatusProvider(JobStatus.cancelled).future);
      await c.read(jobProvider('job-1').future);

      final result = await c
          .read(activityActionsProvider.notifier)
          .cancelJob('job-1', reason: 'Cambio de planes');

      expect(result.valueOrNull?.status, JobStatus.cancelled);
      final cancelled = await c.read(
        jobsByStatusProvider(JobStatus.cancelled).future,
      );
      expect(_ids(cancelled), contains('job-1'));
      final job = await c.read(jobProvider('job-1').future);
      expect(job?.status, JobStatus.cancelled);
    });

    test('cancelJob reports a rejection for a finished job', () async {
      final result = await _container()
          .read(activityActionsProvider.notifier)
          .cancelJob('job-5');
      expect(result.failureOrNull, isA<DataRejected>());
    });

    test('rebook returns the new request and refreshes requests', () async {
      final c = _container();
      var builds = 0;
      c.listen(myServiceRequestsProvider, (_, _) => builds++);
      await c.read(myServiceRequestsProvider.future);

      final result = await c
          .read(activityActionsProvider.notifier)
          .rebook('job-5');

      expect(result.valueOrNull?.status, ServiceRequestStatus.pending);
      await c.read(myServiceRequestsProvider.future);
      expect(builds, greaterThan(1));
    });

    test('cancelRequest cancels and refreshes the request lists', () async {
      final c = _container();
      await c.read(
        requestsByStatusProvider(ServiceRequestStatus.cancelled).future,
      );

      final result = await c
          .read(activityActionsProvider.notifier)
          .cancelRequest('request-1');

      expect(result.valueOrNull?.status, ServiceRequestStatus.cancelled);
      final cancelled = await c.read(
        requestsByStatusProvider(ServiceRequestStatus.cancelled).future,
      );
      expect(_ids(cancelled), contains('request-1'));
    });

    test('a failed cancelRequest leaves the lists alone', () async {
      final result = await _container()
          .read(activityActionsProvider.notifier)
          .cancelRequest('nope');
      expect(result.failureOrNull, isA<DataNotFound>());
    });
  });
}
