import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

ServiceOffer _offer(String id, String serviceId) => ServiceOffer(
  id: id,
  jobServiceId: serviceId,
  offerantId: 'p1',
  rateType: RateType.fixed,
  amountCop: 1,
  zone: '',
  status: OfferStatus.active,
);

const _services = {
  's1': JobService(id: 's1', category: 'Plomería', title: 'A', description: ''),
  's2': JobService(id: 's2', category: 'cleaning', title: 'B', description: ''),
  's3': JobService(id: 's3', category: 'plumbing', title: 'C', description: ''),
};

void main() {
  test('the professional quotes in the categories of their offers', () async {
    final c = ProviderContainer.test(
      overrides: [
        myOffersProvider.overrideWith(
          (ref) async => [
            _offer('o1', 's1'),
            _offer('o2', 's2'),
            _offer('o3', 's3'),
            _offer('o4', 'gone'),
          ],
        ),
        jobServiceProvider.overrideWith((ref, id) async => _services[id]),
      ],
    );

    // Canonical ids, each once, in the catalog's order.
    expect(await c.read(providerCategoriesProvider.future), [
      ServiceCategories.cleaning,
      ServiceCategories.plumbing,
    ]);
  });
}
