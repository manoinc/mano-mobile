import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

// Mirrors the mock fixture offer-1.
const _existing = ServiceOffer(
  id: 'offer-1',
  jobServiceId: '11111111-0000-0000-0000-000000000001',
  offerantId: 'provider-1',
  rateType: RateType.fixed,
  amountCop: 120000,
  zone: 'Chapinero',
  status: OfferStatus.active,
);

final class _CountingCatalog implements ServiceCatalog {
  final offersForCalls = <String>[];

  @override
  Future<List<ServiceOffer>> offersFor(String jobServiceId) async {
    offersForCalls.add(jobServiceId);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RejectingOffers implements OfferManagement {
  @override
  Future<List<ServiceOffer>> myOffers() async => const [_existing];

  @override
  Future<Result<ServiceOffer, DataFailure>> create({
    required String jobServiceId,
    required RateType rateType,
    required int amountCop,
    required String zone,
  }) async => const Err(DataRejected());

  @override
  Future<Result<ServiceOffer, DataFailure>> pause(String offerId) async =>
      const Err(DataUnavailable());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

({ProviderContainer c, _CountingCatalog catalog}) _setUp({
  OfferManagement? offers,
}) {
  final catalog = _CountingCatalog();
  final c = ProviderContainer.test(
    overrides: [
      offerManagementProvider.overrideWithValue(
        offers ?? MockOfferManagement(),
      ),
      serviceCatalogProvider.overrideWithValue(catalog),
    ],
  );
  return (c: c, catalog: catalog);
}

Future<OfferEditorNotifier> _editor(ProviderContainer c, String? id) async {
  c.listen(offerEditorProvider(id), (_, _) {});
  await c.read(offerEditorProvider(id).future);
  return c.read(offerEditorProvider(id).notifier);
}

OfferEditorState _state(ProviderContainer c, String? id) =>
    c.read(offerEditorProvider(id)).requireValue;

void main() {
  test('myOffersProvider lists the provider offers', () async {
    final (:c, catalog: _) = _setUp();
    final offers = await c.read(myOffersProvider.future);
    expect(offers.map((o) => o.id), ['offer-1', 'offer-2', 'offer-3']);
  });

  test('a new draft is empty, fixed-price and invalid', () async {
    final (:c, catalog: _) = _setUp();
    await _editor(c, null);
    final s = _state(c, null);
    expect(s.isNew, isTrue);
    expect(s.jobServiceId, isNull);
    expect(s.rateType, RateType.fixed);
    expect(s.amountCop, 0);
    expect(s.zone, '');
    expect(s.isValid, isFalse);
    expect(s.status, isA<OfferEditorIdle>());
  });

  test('editing seeds the draft from the existing offer', () async {
    final (:c, catalog: _) = _setUp();
    await _editor(c, 'offer-2');
    final s = _state(c, 'offer-2');
    expect(s.isNew, isFalse);
    expect(s.original?.id, 'offer-2');
    expect(s.jobServiceId, '11111111-0000-0000-0000-000000000003');
    expect(s.rateType, RateType.hourly);
    expect(s.amountCop, 45000);
    expect(s.zone, 'Usaquén');
    expect(s.isValid, isTrue);
  });

  test('editing an unknown offer is an error', () async {
    final (:c, catalog: _) = _setUp();
    c.listen(offerEditorProvider('nope'), (_, _) {});
    await expectLater(
      c.read(offerEditorProvider('nope').future),
      throwsA(isA<StateError>()),
    );
  });

  test('valid needs a service and an amount above zero', () async {
    final (:c, catalog: _) = _setUp();
    final n = await _editor(c, null);
    n.selectService('svc-1');
    expect(_state(c, null).isValid, isFalse);
    n.setAmount(50000);
    expect(_state(c, null).isValid, isTrue);
    n.setAmount(0);
    expect(_state(c, null).isValid, isFalse);
  });

  test('the service is fixed once the offer exists', () async {
    final (:c, catalog: _) = _setUp();
    final n = await _editor(c, 'offer-1');
    n.selectService('other');
    expect(_state(c, 'offer-1').jobServiceId, _existing.jobServiceId);
  });

  test('submit is a no-op while the draft is invalid', () async {
    final (:c, catalog: _) = _setUp();
    final n = await _editor(c, null);
    await n.submit();
    expect(_state(c, null).status, isA<OfferEditorIdle>());
    expect(await c.read(myOffersProvider.future), hasLength(3));
  });

  test('submit creates the offer and refreshes the lists', () async {
    final (:c, :catalog) = _setUp();
    final before = await c.read(myOffersProvider.future);
    c.listen(myOffersProvider, (_, _) {});
    c.listen(offersForServiceProvider('svc-1'), (_, _) {});
    await c.read(offersForServiceProvider('svc-1').future);

    final n = await _editor(c, null);
    n
      ..selectService('svc-1')
      ..setRateType(RateType.hourly)
      ..setAmount(50000)
      ..setZone('  Suba ');
    await n.submit();

    final status = _state(c, null).status;
    expect(status, isA<OfferEditorSaved>());
    final saved = (status as OfferEditorSaved).offer;
    expect(saved.jobServiceId, 'svc-1');
    expect(saved.rateType, RateType.hourly);
    expect(saved.amountCop, 50000);
    expect(saved.zone, 'Suba');

    final after = await c.read(myOffersProvider.future);
    expect(after, hasLength(before.length + 1));
    await c.read(offersForServiceProvider('svc-1').future);
    expect(catalog.offersForCalls, ['svc-1', 'svc-1']);
  });

  test('submit on an existing offer updates it', () async {
    final (:c, catalog: _) = _setUp();
    final n = await _editor(c, 'offer-1');
    n
      ..setRateType(RateType.hourly)
      ..setAmount(60000)
      ..setZone('');
    await n.submit();

    final saved = (_state(c, 'offer-1').status as OfferEditorSaved).offer;
    expect(saved.id, 'offer-1');
    expect(saved.rateType, RateType.hourly);
    expect(saved.amountCop, 60000);
    expect(saved.zone, '');
    final listed = await c.read(myOffersProvider.future);
    expect(listed.firstWhere((o) => o.id == 'offer-1').amountCop, 60000);
  });

  test('pause, resume and delete save and refresh the list', () async {
    final (:c, catalog: _) = _setUp();
    final n = await _editor(c, 'offer-1');

    await n.pause();
    var saved = (_state(c, 'offer-1').status as OfferEditorSaved).offer;
    expect(saved.status, OfferStatus.paused);

    final n3 = await _editor(c, 'offer-3');
    await n3.resume();
    saved = (_state(c, 'offer-3').status as OfferEditorSaved).offer;
    expect(saved.status, OfferStatus.active);

    final n2 = await _editor(c, 'offer-2');
    await n2.delete();
    expect(_state(c, 'offer-2').status, isA<OfferEditorSaved>());
    final listed = await c.read(myOffersProvider.future);
    expect(listed.map((o) => o.id), isNot(contains('offer-2')));
    expect(
      listed.firstWhere((o) => o.id == 'offer-1').status,
      OfferStatus.paused,
    );
  });

  test('a rejected mutation fails and keeps the draft', () async {
    final (:c, catalog: _) = _setUp(offers: _RejectingOffers());
    final n = await _editor(c, null);
    n
      ..selectService('svc-1')
      ..setAmount(50000);
    await n.submit();
    final s = _state(c, null);
    expect(s.status, isA<OfferEditorFailed>());
    expect((s.status as OfferEditorFailed).failure, isA<DataRejected>());
    expect(s.amountCop, 50000);

    final e = await _editor(c, 'offer-1');
    await e.pause();
    expect(
      (_state(c, 'offer-1').status as OfferEditorFailed).failure,
      isA<DataUnavailable>(),
    );
  });

  test('editing the draft clears a failure', () async {
    final (:c, catalog: _) = _setUp(offers: _RejectingOffers());
    final n = await _editor(c, null);
    n
      ..selectService('svc-1')
      ..setAmount(50000);
    await n.submit();
    n.setZone('Suba');
    expect(_state(c, null).status, isA<OfferEditorIdle>());
  });
}
