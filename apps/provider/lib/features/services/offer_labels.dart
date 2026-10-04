import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

// Domain → copy for the Servicios screens; mano_ui cannot see these enums.

String pricingModel(RateType rateType) => switch (rateType) {
  RateType.fixed => 'Precio fijo',
  RateType.hourly => 'Por hora',
};

String rateLabel(RateType rateType) => switch (rateType) {
  RateType.fixed => 'precio fijo',
  RateType.hourly => '/hora',
};

(String, ManoStatusTone) offerBadge(OfferStatus status) => switch (status) {
  OfferStatus.active => ('Activa', ManoStatusTone.success),
  OfferStatus.paused => ('Pausada', ManoStatusTone.neutral),
  OfferStatus.deleted => ('Eliminada', ManoStatusTone.neutral),
};
