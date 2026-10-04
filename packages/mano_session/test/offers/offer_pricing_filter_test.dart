import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

ServiceOffer _offer(String id, RateType rate, int amount) => ServiceOffer(
  id: id,
  jobServiceId: 'svc',
  offerantId: 'p',
  rateType: rate,
  amountCop: amount,
  zone: '',
  status: OfferStatus.active,
);

void main() {
  final offers = [
    _offer('a', RateType.hourly, 50000),
    _offer('b', RateType.fixed, 120000),
    _offer('c', RateType.hourly, 30000),
    _offer('d', RateType.fixed, 80000),
  ];

  List<String> ids(List<ServiceOffer> list) => [for (final o in list) o.id];

  test('all keeps every offer, cheapest first', () {
    expect(ids(OfferPricingFilter.all.apply(offers)), ['c', 'a', 'd', 'b']);
  });

  test('fixed keeps fixed-price offers, cheapest first', () {
    expect(ids(OfferPricingFilter.fixed.apply(offers)), ['d', 'b']);
  });

  test('hourly keeps hourly offers, cheapest first', () {
    expect(ids(OfferPricingFilter.hourly.apply(offers)), ['c', 'a']);
  });

  test('does not mutate the input list', () {
    OfferPricingFilter.all.apply(offers);
    expect(ids(offers), ['a', 'b', 'c', 'd']);
  });
}
