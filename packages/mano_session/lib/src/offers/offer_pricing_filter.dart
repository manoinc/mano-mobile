import 'package:mano_domain/mano_domain.dart';

/// Which pricing model an offer list shows; results are always cheapest first.
enum OfferPricingFilter {
  all(null),
  fixed(RateType.fixed),
  hourly(RateType.hourly);

  const OfferPricingFilter(this._rateType);

  final RateType? _rateType;

  List<ServiceOffer> apply(List<ServiceOffer> offers) => [
    for (final offer in offers)
      if (_rateType == null || offer.rateType == _rateType) offer,
  ]..sort((a, b) => a.amountCop.compareTo(b.amountCop));
}
