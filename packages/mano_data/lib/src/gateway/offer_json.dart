import 'package:mano_domain/mano_domain.dart';

/// The `JobServiceOffer` selection every query reads with [offerFromJson].
const offerFields = 'id jobServiceId offerantId rateType amount zone status';

/// A gateway `JobServiceOffer` as a [ServiceOffer]; `amount` is a Decimal number.
ServiceOffer offerFromJson(Map<String, dynamic> json) => ServiceOffer(
  id: json['id'] as String,
  jobServiceId: json['jobServiceId'] as String,
  offerantId: json['offerantId'] as String,
  rateType: switch (json['rateType']) {
    'HOURLY' => RateType.hourly,
    _ => RateType.fixed,
  },
  amountCop: (json['amount'] as num).round(),
  zone: json['zone'] as String,
  status: switch (json['status']) {
    'PAUSED' => OfferStatus.paused,
    'DELETED' => OfferStatus.deleted,
    _ => OfferStatus.active,
  },
);

/// The gateway's `RateType` enum value.
String rateTypeToJson(RateType rateType) => switch (rateType) {
  RateType.fixed => 'FIXED',
  RateType.hourly => 'HOURLY',
};
