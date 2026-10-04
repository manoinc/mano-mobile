import 'package:mano_session/mano_session.dart';

const limpieza = JobService(
  id: 'svc-1',
  category: 'Limpieza',
  title: 'Limpieza profunda',
  description: 'Toda la casa',
);

const plomeria = JobService(
  id: 'svc-2',
  category: 'Plomería',
  title: 'Reparación de fugas',
  description: 'Tuberías y grifos',
);

/// An in-memory catalog; search filters titles by [text] when given.
final class FakeServiceCatalog implements ServiceCatalog {
  FakeServiceCatalog({this.services = const [limpieza, plomeria]});

  final List<JobService> services;

  @override
  Future<List<JobService>> search({String? category, String? text}) async => [
    for (final s in services)
      if (text == null || s.title.toLowerCase().contains(text.toLowerCase())) s,
  ];

  @override
  Future<JobService?> service(String id) async =>
      services.where((s) => s.id == id).firstOrNull;

  @override
  Future<ServiceOffer?> offer(String id) async => null;

  @override
  Future<List<ServiceOffer>> offersFor(String jobServiceId) async => const [];
}

ServiceOffer offer(
  String id, {
  String jobServiceId = 'svc-1',
  RateType rateType = RateType.fixed,
  int amountCop = 120000,
  String zone = 'Chapinero',
  OfferStatus status = OfferStatus.active,
}) => ServiceOffer(
  id: id,
  jobServiceId: jobServiceId,
  offerantId: 'provider-1',
  rateType: rateType,
  amountCop: amountCop,
  zone: zone,
  status: status,
);

/// Holds offers in memory; [fail] makes every mutation return it, [failList] makes listing throw.
final class FakeOfferManagement implements OfferManagement {
  FakeOfferManagement([List<ServiceOffer> offers = const []])
    : _offers = [...offers];

  final List<ServiceOffer> _offers;
  DataFailure? fail;
  bool failList = false;
  int listCalls = 0;

  @override
  Future<List<ServiceOffer>> myOffers() async {
    listCalls++;
    if (failList) throw StateError('gateway down');
    return [
      for (final o in _offers)
        if (o.status != OfferStatus.deleted) o,
    ];
  }

  @override
  Future<Result<ServiceOffer, DataFailure>> create({
    required String jobServiceId,
    required RateType rateType,
    required int amountCop,
    required String zone,
  }) async => _save(
    offer(
      'new-${_offers.length}',
      jobServiceId: jobServiceId,
      rateType: rateType,
      amountCop: amountCop,
      zone: zone,
    ),
  );

  @override
  Future<Result<ServiceOffer, DataFailure>> update(
    String offerId, {
    RateType? rateType,
    int? amountCop,
    String? zone,
  }) async => _change(
    offerId,
    (o) => o.copyWith(rateType: rateType, amountCop: amountCop, zone: zone),
  );

  @override
  Future<Result<ServiceOffer, DataFailure>> pause(String offerId) async =>
      _change(offerId, (o) => o.copyWith(status: OfferStatus.paused));

  @override
  Future<Result<ServiceOffer, DataFailure>> resume(String offerId) async =>
      _change(offerId, (o) => o.copyWith(status: OfferStatus.active));

  @override
  Future<Result<ServiceOffer, DataFailure>> delete(String offerId) async =>
      _change(offerId, (o) => o.copyWith(status: OfferStatus.deleted));

  Result<ServiceOffer, DataFailure> _save(ServiceOffer o) {
    if (fail case final f?) return Err(f);
    _offers.add(o);
    return Ok(o);
  }

  Result<ServiceOffer, DataFailure> _change(
    String id,
    ServiceOffer Function(ServiceOffer) change,
  ) {
    if (fail case final f?) return Err(f);
    final i = _offers.indexWhere((o) => o.id == id);
    if (i < 0) return const Err(DataNotFound());
    return Ok(_offers[i] = change(_offers[i]));
  }
}
