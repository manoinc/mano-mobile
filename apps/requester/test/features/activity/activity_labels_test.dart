import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/activity/activity_labels.dart';
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
    expect(jobBadge(_job(JobStatus.cancelled, cancelledBy: JobParty.worker)), (
      'Cancelado por el profesional',
      ManoStatusTone.neutral,
    ));
    expect(
      jobBadge(_job(JobStatus.cancelled, cancelledBy: JobParty.client)).$1,
      'Cancelaste este trabajo',
    );
    expect(jobBadge(_job(JobStatus.cancelled)).$1, 'Cancelado');
  });

  test('a live job keeps its status label', () {
    expect(jobBadge(_job(JobStatus.scheduled)).$1, 'Programado');
  });
}
