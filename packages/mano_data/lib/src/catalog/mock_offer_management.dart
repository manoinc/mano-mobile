import 'package:mano_domain/mano_domain.dart';

import '../mock/mock_fixtures.dart';

/// In-memory [OfferManagement]; the gateway has no "list my offers" yet.
final class MockOfferManagement implements OfferManagement {
  MockOfferManagement() : _offers = [...mockOffers];

  final List<ServiceOffer> _offers;
  int _nextId = 100;

  @override
  Future<List<ServiceOffer>> myOffers() async =>
      _offers.where((o) => o.status != OfferStatus.deleted).toList();

  @override
  Future<Result<ServiceOffer, DataFailure>> create({
    required String jobServiceId,
    required RateType rateType,
    required int amountCop,
    required String zone,
  }) async {
    if (amountCop < 0) return const Err(DataRejected(reason: 'amount < 0'));
    final offer = ServiceOffer(
      id: 'offer-${_nextId++}',
      jobServiceId: jobServiceId,
      offerantId: mockProviders.first.id,
      rateType: rateType,
      amountCop: amountCop,
      zone: zone,
      status: OfferStatus.active,
    );
    _offers.add(offer);
    return Ok(offer);
  }

  @override
  Future<Result<ServiceOffer, DataFailure>> update(
    String offerId, {
    RateType? rateType,
    int? amountCop,
    String? zone,
  }) async {
    if (amountCop != null && amountCop < 0) {
      return const Err(DataRejected(reason: 'amount < 0'));
    }
    return _replace(
      offerId,
      (o) => o.copyWith(rateType: rateType, amountCop: amountCop, zone: zone),
    );
  }

  @override
  Future<Result<ServiceOffer, DataFailure>> pause(String offerId) async =>
      _transition(offerId, from: OfferStatus.active, to: OfferStatus.paused);

  @override
  Future<Result<ServiceOffer, DataFailure>> resume(String offerId) async =>
      _transition(offerId, from: OfferStatus.paused, to: OfferStatus.active);

  @override
  Future<Result<ServiceOffer, DataFailure>> delete(String offerId) async =>
      _replace(offerId, (o) => o.copyWith(status: OfferStatus.deleted));

  Result<ServiceOffer, DataFailure> _transition(
    String id, {
    required OfferStatus from,
    required OfferStatus to,
  }) {
    final index = _offers.indexWhere((o) => o.id == id);
    if (index < 0) return const Err(DataNotFound());
    if (_offers[index].status != from) {
      return Err(DataRejected(reason: 'offer is ${_offers[index].status}'));
    }
    return _replace(id, (o) => o.copyWith(status: to));
  }

  Result<ServiceOffer, DataFailure> _replace(
    String id,
    ServiceOffer Function(ServiceOffer) change,
  ) {
    final index = _offers.indexWhere(
      (o) => o.id == id && o.status != OfferStatus.deleted,
    );
    if (index < 0) return const Err(DataNotFound());
    return Ok(_offers[index] = change(_offers[index]));
  }
}
