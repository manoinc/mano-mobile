import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

// Domain → copy for the Solicitudes screens; mano_ui cannot see these enums.

(String, ManoStatusTone) requestBadge(ServiceRequestStatus status) =>
    switch (status) {
      ServiceRequestStatus.pending => ('Pendiente', ManoStatusTone.info),
      ServiceRequestStatus.accepted => ('Aceptada', ManoStatusTone.success),
      ServiceRequestStatus.rejected => ('Rechazada', ManoStatusTone.neutral),
      ServiceRequestStatus.cancelled => ('Cancelada', ManoStatusTone.neutral),
    };

String rateLabel(RateType rateType) => switch (rateType) {
  RateType.hourly => '/hora',
  RateType.fixed => 'precio fijo',
};

String scheduleLabel(ServiceRequest request) {
  final when = request.proposedStart;
  return when == null ? 'Sin horario propuesto' : ManoFormat.dateTime(when);
}
