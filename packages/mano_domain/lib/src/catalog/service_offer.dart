enum RateType { fixed, hourly }

enum OfferStatus { active, paused, deleted }

/// One provider's priced listing against a [JobService].
final class ServiceOffer {
  const ServiceOffer({
    required this.id,
    required this.jobServiceId,
    required this.offerantId,
    required this.rateType,
    required this.amountCop,
    required this.zone,
    required this.status,
  });

  final String id;
  final String jobServiceId;
  final String offerantId;
  final RateType rateType;

  /// Whole pesos: the price when fixed, the hourly rate when hourly.
  final int amountCop;

  /// Free text; empty means the provider named no zone.
  final String zone;
  final OfferStatus status;

  bool get hasZone => zone.isNotEmpty;

  ServiceOffer copyWith({
    RateType? rateType,
    int? amountCop,
    String? zone,
    OfferStatus? status,
  }) => ServiceOffer(
    id: id,
    jobServiceId: jobServiceId,
    offerantId: offerantId,
    rateType: rateType ?? this.rateType,
    amountCop: amountCop ?? this.amountCop,
    zone: zone ?? this.zone,
    status: status ?? this.status,
  );

  @override
  bool operator ==(Object other) =>
      other is ServiceOffer &&
      other.id == id &&
      other.jobServiceId == jobServiceId &&
      other.offerantId == offerantId &&
      other.rateType == rateType &&
      other.amountCop == amountCop &&
      other.zone == zone &&
      other.status == status;

  @override
  int get hashCode => Object.hash(
    id,
    jobServiceId,
    offerantId,
    rateType,
    amountCop,
    zone,
    status,
  );

  @override
  String toString() => 'ServiceOffer($id, $rateType $amountCop COP)';
}
