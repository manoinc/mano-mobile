import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

// Domain → copy for the Actividad screens; mano_ui cannot see these enums.

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
  JobParty.worker => 'Cancelado por el profesional',
  JobParty.client => 'Cancelaste este trabajo',
  null => 'Cancelado',
};

(String, ManoStatusTone) requestBadge(ServiceRequestStatus status) =>
    switch (status) {
      ServiceRequestStatus.pending => ('Pendiente', ManoStatusTone.info),
      ServiceRequestStatus.accepted => ('Aceptada', ManoStatusTone.success),
      ServiceRequestStatus.rejected => ('Rechazada', ManoStatusTone.neutral),
      ServiceRequestStatus.cancelled => ('Cancelada', ManoStatusTone.neutral),
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
