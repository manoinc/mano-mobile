import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

const _party = Party(id: 'p', displayName: 'Ana', photoUrl: '');

Job _job({
  RateType rateType = RateType.fixed,
  double? actualHours,
  int? finalAmountCop,
}) => Job(
  id: 'job-1',
  offerId: 'offer-1',
  serviceTitle: 'Plomería',
  client: _party,
  provider: _party,
  rateType: rateType,
  amountCop: 50000,
  start: DateTime(2026, 11, 8),
  status: JobStatus.finished,
  actualHours: actualHours,
  finalAmountCop: finalAmountCop,
);

void main() {
  test('a fixed job is paid at its price', () {
    expect(_job().payableCop, 50000);
  });

  test('an hourly job is paid at rate × hours worked', () {
    expect(
      _job(rateType: RateType.hourly, actualHours: 2.5).payableCop,
      125000,
    );
  });

  test("the gateway's final amount wins", () {
    expect(
      _job(rateType: RateType.hourly, finalAmountCop: 62500).payableCop,
      62500,
    );
  });

  test('copyWith keeps the final amount', () {
    final job = _job(finalAmountCop: 62500);
    expect(job.copyWith(status: JobStatus.finished).finalAmountCop, 62500);
    expect(job == _job(finalAmountCop: 62500), isTrue);
    expect(job == _job(), isFalse);
  });
}
