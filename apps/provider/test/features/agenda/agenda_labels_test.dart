import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/agenda/agenda_labels.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

const _party = Party(id: 'p', displayName: 'Ana', photoUrl: '');

Job _job(JobStatus status, {JobParty? cancelledBy}) => Job(
  id: 'j',
  offerId: 'o',
  serviceTitle: 'Plomería',
  client: _party,
  provider: _party,
  rateType: RateType.fixed,
  amountCop: 1,
  start: DateTime(2026, 11, 9),
  status: status,
  cancelledBy: cancelledBy,
);

void main() {
  test('a cancelled job says who cancelled it', () {
    expect(jobBadge(_job(JobStatus.cancelled, cancelledBy: JobParty.client)), (
      'Cancelado por el cliente',
      ManoStatusTone.neutral,
    ));
    expect(
      jobBadge(_job(JobStatus.cancelled, cancelledBy: JobParty.worker)).$1,
      'Cancelaste este trabajo',
    );
    expect(jobBadge(_job(JobStatus.cancelled)).$1, 'Cancelado');
    expect(jobBadge(_job(JobStatus.inProgress)).$1, 'En curso');
  });

  final today = DateTime(2026, 10, 4, 15);

  test('dayLabel names today and tomorrow, else weekday and date', () {
    expect(dayLabel(DateTime(2026, 10, 4), today), 'Hoy');
    expect(dayLabel(DateTime(2026, 10, 5), today), 'Mañana');
    final later = DateTime(2026, 10, 8);
    expect(
      dayLabel(later, today),
      '${ManoFormat.weekdayShort(later)} ${ManoFormat.dayMonth(later)}',
    );
  });

  test('hoursLabel uses a decimal comma and drops whole decimals', () {
    expect(hoursLabel(2.5), '2,5 h');
    expect(hoursLabel(3), '3 h');
  });

  test('shortPrice adds /hora for hourly jobs', () {
    expect(shortPrice(45000, RateType.hourly), r'$45.000/hora');
    expect(shortPrice(120000, RateType.fixed), r'$120.000');
  });
}
