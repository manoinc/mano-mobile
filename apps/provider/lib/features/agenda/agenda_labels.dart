import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

// Domain → copy for the agenda screens; mano_ui cannot see these enums.

/// A list card's badge: plain status, "Cancelado" whoever cancelled.
(String, ManoStatusTone) jobBadge(JobStatus status) => switch (status) {
  JobStatus.scheduled => ('Programado', ManoStatusTone.info),
  JobStatus.inProgress => ('En curso', ManoStatusTone.warning),
  JobStatus.finished => ('Finalizado', ManoStatusTone.success),
  JobStatus.cancelled => ('Cancelado', ManoStatusTone.neutral),
};

/// A detail or history badge, saying who cancelled.
(String, ManoStatusTone) jobDetailBadge(Job job) =>
    job.status == JobStatus.cancelled
    ? (_cancelledBy(job.cancelledBy), ManoStatusTone.neutral)
    : jobBadge(job.status);

String _cancelledBy(JobParty? party) => switch (party) {
  JobParty.worker => 'Cancelaste este trabajo',
  JobParty.client => 'Cancelado por el cliente',
  null => 'Cancelado',
};

/// "$45.000/hora" or "$120.000", for a card.
String shortPrice(int amountCop, RateType rateType) => switch (rateType) {
  RateType.hourly => '${ManoFormat.cop(amountCop)}/hora',
  RateType.fixed => ManoFormat.cop(amountCop),
};

String rateLabel(RateType rateType) => switch (rateType) {
  RateType.hourly => 'por hora',
  RateType.fixed => 'precio fijo',
};

/// "Hoy", "Mañana", or "vie 9 oct" for a section header.
String dayLabel(DateTime day, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(day.year, day.month, day.day);
  final offset = (date.difference(today).inHours / 24).round();
  return switch (offset) {
    0 => 'Hoy',
    1 => 'Mañana',
    _ => '${ManoFormat.weekdayShort(date)} ${ManoFormat.dayMonth(date)}',
  };
}

/// "2,5 h" or "3 h".
String hoursLabel(double hours) {
  final text = hours == hours.roundToDouble()
      ? hours.toStringAsFixed(0)
      : hours.toStringAsFixed(1).replaceAll('.', ',');
  return '$text h';
}
