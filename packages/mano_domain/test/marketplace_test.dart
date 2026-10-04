import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

const _client = Party(id: 'c1', displayName: 'Laura', photoUrl: '');
const _provider = Party(id: 'p1', displayName: 'Andrés', photoUrl: '');

ServiceOffer _offer({RateType rateType = RateType.fixed, String zone = ''}) =>
    ServiceOffer(
      id: 'o1',
      jobServiceId: 's1',
      offerantId: 'p1',
      rateType: rateType,
      amountCop: 80000,
      zone: zone,
      status: OfferStatus.active,
    );

Job _job(JobStatus status, {RateType rateType = RateType.fixed}) => Job(
  id: 'j1',
  offerId: 'o1',
  serviceTitle: 'Limpieza profunda',
  client: _client,
  provider: _provider,
  rateType: rateType,
  amountCop: 80000,
  start: DateTime(2026, 10, 10, 9),
  status: status,
);

ServiceRequest _request(ServiceRequestStatus status) => ServiceRequest(
  id: 'r1',
  offer: _offer(),
  serviceTitle: 'Limpieza profunda',
  client: _client,
  provider: _provider,
  message: 'Hola',
  status: status,
  createdAt: DateTime(2026, 10, 1),
);

void main() {
  group('ServiceOffer', () {
    test('identical offers are equal and share a hashCode', () {
      expect(_offer(), _offer());
      expect(_offer().hashCode, _offer().hashCode);
    });

    test('an empty zone means no zone', () {
      expect(_offer().hasZone, isFalse);
      expect(_offer(zone: 'Chapinero').hasZone, isTrue);
    });
  });

  group('JobService', () {
    test('identical services are equal', () {
      const a = JobService(id: 's1', category: 'cleaning', title: 'Aseo', description: 'd');
      const b = JobService(id: 's1', category: 'cleaning', title: 'Aseo', description: 'd');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('Job lifecycle', () {
    test('only a scheduled job can start', () {
      expect(_job(JobStatus.scheduled).canStart, isTrue);
      for (final s in [JobStatus.inProgress, JobStatus.finished, JobStatus.cancelled]) {
        expect(_job(s).canStart, isFalse, reason: '$s');
      }
    });

    test('only a job in progress can finish', () {
      expect(_job(JobStatus.inProgress).canFinish, isTrue);
      expect(_job(JobStatus.scheduled).canFinish, isFalse);
    });

    test('scheduled and in-progress jobs can be cancelled', () {
      expect(_job(JobStatus.scheduled).canCancel, isTrue);
      expect(_job(JobStatus.inProgress).canCancel, isTrue);
      expect(_job(JobStatus.finished).canCancel, isFalse);
      expect(_job(JobStatus.cancelled).canCancel, isFalse);
    });

    test('only finished or cancelled jobs can be rebooked', () {
      expect(_job(JobStatus.finished).canRebook, isTrue);
      expect(_job(JobStatus.cancelled).canRebook, isTrue);
      expect(_job(JobStatus.scheduled).canRebook, isFalse);
    });

    test('hourly jobs need logged hours to finish', () {
      expect(_job(JobStatus.inProgress, rateType: RateType.hourly).requiresHoursOnFinish, isTrue);
      expect(_job(JobStatus.inProgress).requiresHoursOnFinish, isFalse);
    });

    test('copyWith changes only what it is given', () {
      final started = _job(JobStatus.scheduled).copyWith(status: JobStatus.inProgress);
      expect(started.status, JobStatus.inProgress);
      expect(started.id, 'j1');
    });
  });

  group('ServiceRequest', () {
    test('only a pending request can be answered or cancelled', () {
      expect(_request(ServiceRequestStatus.pending).canRespond, isTrue);
      expect(_request(ServiceRequestStatus.pending).canCancel, isTrue);
      for (final s in [
        ServiceRequestStatus.accepted,
        ServiceRequestStatus.rejected,
        ServiceRequestStatus.cancelled,
      ]) {
        expect(_request(s).canRespond, isFalse, reason: '$s');
        expect(_request(s).canCancel, isFalse, reason: '$s');
      }
    });
  });

  group('AvailabilityRule', () {
    AvailabilityRule rule({
      Set<int> weekdays = const {DateTime.monday},
      int startMinutes = 8 * 60,
      int durationMinutes = 240,
    }) => AvailabilityRule(
      weekdays: weekdays,
      startMinutes: startMinutes,
      durationMinutes: durationMinutes,
    );

    test('a weekday morning block is valid', () {
      expect(rule().isValid, isTrue);
    });

    test('durations must be positive multiples of 30 minutes', () {
      expect(rule(durationMinutes: 45).isValid, isFalse);
      expect(rule(durationMinutes: 0).isValid, isFalse);
    });

    test('a rule needs at least one weekday', () {
      expect(rule(weekdays: const {}).isValid, isFalse);
    });

    test('a rule cannot run past midnight', () {
      expect(rule(startMinutes: 22 * 60, durationMinutes: 180).isValid, isFalse);
    });
  });

  group('DataFailure', () {
    test('every case has a user-facing message', () {
      const failures = <DataFailure>[
        DataNotFound(),
        DataRejected(reason: 'x'),
        DataUnavailable(detail: 'y'),
      ];
      for (final f in failures) {
        expect(f.message, isNotEmpty);
      }
    });
  });
}
