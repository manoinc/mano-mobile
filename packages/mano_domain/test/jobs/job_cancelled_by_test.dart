import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

const _party = Party(id: 'p', displayName: 'Ana', photoUrl: '');

Job _job({JobParty? cancelledBy}) => Job(
  id: 'job-1',
  offerId: 'offer-1',
  serviceTitle: 'Plomería',
  client: _party,
  provider: _party,
  rateType: RateType.fixed,
  amountCop: 50000,
  start: DateTime(2026, 11, 8),
  status: JobStatus.cancelled,
  cancelledBy: cancelledBy,
);

void main() {
  test('a legacy cancellation does not know who cancelled', () {
    expect(_job().cancelledBy, isNull);
  });

  test('who cancelled is part of the job', () {
    expect(_job(cancelledBy: JobParty.worker).cancelledBy, JobParty.worker);
    expect(
      _job(cancelledBy: JobParty.client),
      isNot(_job(cancelledBy: JobParty.worker)),
    );
  });

  test('copyWith keeps or sets who cancelled', () {
    final job = _job(cancelledBy: JobParty.client);
    expect(job.copyWith(actualHours: 1).cancelledBy, JobParty.client);
    expect(
      _job().copyWith(cancelledBy: JobParty.worker).cancelledBy,
      JobParty.worker,
    );
  });
}
