import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

final _now = DateTime(2026, 10, 4, 12);

ProviderContainer _container() => ProviderContainer.test(
  overrides: [
    jobRepositoryProvider.overrideWithValue(MockJobRepository(now: () => _now)),
  ],
);

List<String> _ids(Iterable<Job> jobs) => [for (final j in jobs) j.id];

const _party = Party(id: 'p', displayName: 'P', photoUrl: '');

Job _jobAt(String id, DateTime start) => Job(
  id: id,
  offerId: 'o',
  serviceTitle: 's',
  client: _party,
  provider: _party,
  rateType: RateType.fixed,
  amountCop: 1,
  start: start,
  status: JobStatus.scheduled,
);

void main() {
  group('selectors', () {
    test('upcomingJobsProvider lists scheduled jobs soonest first', () async {
      final c = _container();
      await c
          .read(jobRepositoryProvider)
          .bookSlot('offer-1', DateTime(2026, 10, 5, 9));

      final upcoming = await c.read(upcomingJobsProvider.future);

      expect(_ids(upcoming), ['job-100', 'job-1', 'job-2']);
    });

    test(
      'jobHistoryProvider lists finished and cancelled, newest first',
      () async {
        final history = await _container().read(jobHistoryProvider.future);
        expect(_ids(history), ['job-6', 'job-5']);
      },
    );
  });

  test('groupJobsByDay groups jobs by calendar day, in order', () {
    final groups = groupJobsByDay([
      _jobAt('a', DateTime(2026, 10, 4, 9)),
      _jobAt('b', DateTime(2026, 10, 4, 15)),
      _jobAt('c', DateTime(2026, 10, 6, 8)),
    ]);

    expect(
      [for (final g in groups) g.day],
      [DateTime(2026, 10, 4), DateTime(2026, 10, 6)],
    );
    expect(
      [for (final g in groups) _ids(g.jobs)],
      [
        ['a', 'b'],
        ['c'],
      ],
    );
  });

  group('AgendaActions', () {
    test('start moves a job in progress and refreshes reads', () async {
      final c = _container();
      await c.read(upcomingJobsProvider.future);
      await c.read(jobProvider('job-1').future);

      final result = await c
          .read(agendaActionsProvider.notifier)
          .start('job-1');

      expect(result.valueOrNull?.status, JobStatus.inProgress);
      expect(_ids(await c.read(upcomingJobsProvider.future)), ['job-2']);
      expect(
        (await c.read(jobProvider('job-1').future))?.status,
        JobStatus.inProgress,
      );
    });

    test('finish records hours on an hourly job and refreshes reads', () async {
      final c = _container();
      await c.read(jobHistoryProvider.future);
      await c.read(jobProvider('job-3').future);

      final result = await c
          .read(agendaActionsProvider.notifier)
          .finish('job-3', actualHours: 2.5);

      expect(result.valueOrNull?.actualHours, 2.5);
      expect(_ids(await c.read(jobHistoryProvider.future)), contains('job-3'));
      expect(
        (await c.read(jobProvider('job-3').future))?.status,
        JobStatus.finished,
      );
    });

    test('finish without hours on an hourly job is rejected', () async {
      final result = await _container()
          .read(agendaActionsProvider.notifier)
          .finish('job-3');
      expect(result.failureOrNull, isA<DataRejected>());
    });

    test('a failure leaves the reads alone', () async {
      final c = _container();
      final before = await c.read(upcomingJobsProvider.future);

      final result = await c
          .read(agendaActionsProvider.notifier)
          .start('job-5');

      expect(result.failureOrNull, isA<DataRejected>());
      expect(
        identical(await c.read(upcomingJobsProvider.future), before),
        isTrue,
      );
    });
  });
}
