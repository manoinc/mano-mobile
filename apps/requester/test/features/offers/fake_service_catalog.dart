import 'package:mano_session/mano_session.dart';

/// An in-memory catalog; [failOffers] makes `offersFor` throw until cleared.
final class FakeServiceCatalog implements ServiceCatalog {
  FakeServiceCatalog({this.services = const [], this.offers = const []});

  final List<JobService> services;
  final List<ServiceOffer> offers;
  bool failOffers = false;
  int offersCalls = 0;

  @override
  Future<List<JobService>> search({String? category, String? text}) async =>
      services;

  @override
  Future<JobService?> service(String id) async =>
      services.where((s) => s.id == id).firstOrNull;

  @override
  Future<ServiceOffer?> offer(String id) async =>
      offers.where((o) => o.id == id).firstOrNull;

  @override
  Future<List<ServiceOffer>> offersFor(String jobServiceId) async {
    offersCalls++;
    if (failOffers) throw StateError('gateway down');
    return [
      for (final o in offers)
        if (o.jobServiceId == jobServiceId && o.status == OfferStatus.active) o,
    ];
  }
}

const fakeService = JobService(
  id: 'svc-1',
  category: 'Limpieza',
  title: 'Limpieza profunda',
  description: 'Toda la casa',
);

ServiceOffer fakeOffer(
  String id, {
  RateType rateType = RateType.fixed,
  int amountCop = 100000,
  String zone = '',
}) => ServiceOffer(
  id: id,
  jobServiceId: fakeService.id,
  offerantId: 'provider-$id',
  rateType: rateType,
  amountCop: amountCop,
  zone: zone,
  status: OfferStatus.active,
);
