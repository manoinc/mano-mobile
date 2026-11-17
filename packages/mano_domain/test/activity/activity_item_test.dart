import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

const _party = Party(id: 'p', displayName: 'Ana', photoUrl: '');
const _offer = ServiceOffer(
  id: 'offer-1',
  jobServiceId: 'service-1',
  offerantId: 'p',
  rateType: RateType.fixed,
  amountCop: 50000,
  zone: '',
  status: OfferStatus.active,
);

ServiceRequest _request(
  String id,
  ServiceRequestStatus status, [
  DateTime? createdAt,
]) => ServiceRequest(
  id: id,
  offer: _offer,
  serviceTitle: 'Plomería',
  client: _party,
  provider: _party,
  message: '',
  status: status,
  createdAt: createdAt ?? DateTime(2026, 11, 1),
);

Job _job(String id, JobStatus status, [DateTime? start]) => Job(
  id: id,
  offerId: 'offer-1',
  serviceTitle: 'Plomería',
  client: _party,
  provider: _party,
  rateType: RateType.fixed,
  amountCop: 50000,
  start: start ?? DateTime(2026, 11, 1),
  status: status,
);

Project _project(String id, ProjectStatus status, [DateTime? createdAt]) =>
    Project(
      id: id,
      category: 'painting',
      title: 'Pintar',
      description: '',
      status: status,
      createdAt: createdAt ?? DateTime(2026, 11, 1),
    );

String _id(ActivityItem item) => switch (item) {
  RequestActivity(:final request) => request.id,
  JobActivity(:final job) => job.id,
  ProjectActivity(:final project) => project.id,
};

void main() {
  group('bucket', () {
    test('every request status has its place', () {
      const expected = {
        ServiceRequestStatus.pending: ActivityBucket.pending,
        // Accepting creates a job, which stands for it.
        ServiceRequestStatus.accepted: null,
        ServiceRequestStatus.rejected: ActivityBucket.history,
        ServiceRequestStatus.cancelled: ActivityBucket.history,
      };
      for (final status in ServiceRequestStatus.values) {
        expect(
          RequestActivity(_request('r', status)).bucket,
          expected[status],
          reason: '$status',
        );
      }
    });

    test('every job status has its place', () {
      const expected = {
        JobStatus.scheduled: ActivityBucket.active,
        JobStatus.inProgress: ActivityBucket.active,
        JobStatus.finished: ActivityBucket.history,
        JobStatus.cancelled: ActivityBucket.history,
      };
      for (final status in JobStatus.values) {
        expect(
          JobActivity(_job('j', status)).bucket,
          expected[status],
          reason: '$status',
        );
      }
    });

    test('every project status has its place', () {
      const expected = {
        ProjectStatus.open: ActivityBucket.pending,
        ProjectStatus.awarded: ActivityBucket.active,
        ProjectStatus.closed: ActivityBucket.history,
        ProjectStatus.cancelled: ActivityBucket.history,
      };
      for (final status in ProjectStatus.values) {
        expect(
          ProjectActivity(_project('p', status)).bucket,
          expected[status],
          reason: '$status',
        );
      }
    });
  });

  group('sortedAt', () {
    test('a request sorts by when it was asked', () {
      final at = DateTime(2026, 11, 3);
      expect(
        RequestActivity(_request('r', ServiceRequestStatus.pending, at))
            .sortedAt,
        at,
      );
    });

    test('a job sorts by its start', () {
      final at = DateTime(2026, 11, 4, 9);
      expect(JobActivity(_job('j', JobStatus.scheduled, at)).sortedAt, at);
    });

    test('a project sorts by when it was published', () {
      final at = DateTime(2026, 11, 2);
      expect(
        ProjectActivity(_project('p', ProjectStatus.open, at)).sortedAt,
        at,
      );
    });
  });

  group('activityIn', () {
    final requests = [
      _request('r-old', ServiceRequestStatus.pending, DateTime(2026, 11, 1)),
      _request('r-new', ServiceRequestStatus.pending, DateTime(2026, 11, 5)),
      _request('r-accepted', ServiceRequestStatus.accepted),
      _request('r-rejected', ServiceRequestStatus.rejected),
    ];
    final jobs = [
      _job('j-scheduled', JobStatus.scheduled, DateTime(2026, 11, 9)),
      _job('j-running', JobStatus.inProgress, DateTime(2026, 11, 3)),
      _job('j-done', JobStatus.finished, DateTime(2026, 10, 20)),
    ];
    final projects = [
      _project('p-open', ProjectStatus.open, DateTime(2026, 11, 3)),
      _project('p-awarded', ProjectStatus.awarded, DateTime(2026, 11, 6)),
      _project('p-cancelled', ProjectStatus.cancelled, DateTime(2026, 10, 25)),
    ];

    List<String> ids(ActivityBucket bucket) => [
      for (final item in activityIn(
        bucket,
        requests: requests,
        jobs: jobs,
        projects: projects,
      ))
        _id(item),
    ];

    test('pending mixes requests and open projects, newest first', () {
      expect(ids(ActivityBucket.pending), ['r-new', 'p-open', 'r-old']);
    });

    test('active mixes running jobs and awarded projects, newest first', () {
      expect(ids(ActivityBucket.active), [
        'j-scheduled',
        'p-awarded',
        'j-running',
      ]);
    });

    test('history keeps everything that is over, newest first', () {
      expect(ids(ActivityBucket.history), [
        'r-rejected',
        'p-cancelled',
        'j-done',
      ]);
    });

    test('ties keep requests, then jobs, then projects, in source order', () {
      final at = DateTime(2026, 11, 1);
      final tied = activityIn(
        ActivityBucket.history,
        requests: [
          _request('r-1', ServiceRequestStatus.cancelled, at),
          _request('r-2', ServiceRequestStatus.rejected, at),
        ],
        jobs: [_job('j-1', JobStatus.cancelled, at)],
        projects: [_project('p-1', ProjectStatus.closed, at)],
      );
      expect([for (final i in tied) _id(i)], ['r-1', 'r-2', 'j-1', 'p-1']);
    });
  });
}
