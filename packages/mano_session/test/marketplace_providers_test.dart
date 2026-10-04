import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

final class _Catalog implements ServiceCatalog {
  static const aService = JobService(
    id: 's1',
    category: 'cleaning',
    title: 'Aseo',
    description: '',
  );
  static const offerA = ServiceOffer(
    id: 'o1',
    jobServiceId: 's1',
    offerantId: 'p1',
    rateType: RateType.fixed,
    amountCop: 1,
    zone: '',
    status: OfferStatus.active,
  );

  @override
  Future<List<JobService>> search({String? category, String? text}) async => [
    aService,
  ];
  @override
  Future<JobService?> service(String id) async => id == 's1' ? aService : null;
  @override
  Future<ServiceOffer?> offer(String id) async => id == 'o1' ? offerA : null;
  @override
  Future<List<ServiceOffer>> offersFor(String jobServiceId) async => [offerA];
}

ProviderContainer _container() => ProviderContainer.test(
  overrides: [
    manoConfigProvider.overrideWithValue(
      const ManoConfig(gatewayGraphQlUrl: 'http://gw/graphql'),
    ),
  ],
);

void main() {
  test('the catalog reads from the live gateway', () {
    expect(
      _container().read(serviceCatalogProvider),
      isA<GatewayServiceCatalog>(),
    );
  });

  test('stubbed backend ports default to mock adapters', () {
    final c = _container();
    expect(c.read(offerManagementProvider), isA<MockOfferManagement>());
    expect(
      c.read(serviceRequestRepositoryProvider),
      isA<MockServiceRequestRepository>(),
    );
    expect(c.read(jobRepositoryProvider), isA<MockJobRepository>());
    expect(
      c.read(availabilityRepositoryProvider),
      isA<MockAvailabilityRepository>(),
    );
    expect(c.read(chatRepositoryProvider), isA<MockChatRepository>());
    expect(
      c.read(providerOnboardingRepositoryProvider),
      isA<MockProviderOnboardingRepository>(),
    );
  });

  test('a mock keeps its state for the life of the container', () {
    final c = _container();
    expect(
      identical(c.read(jobRepositoryProvider), c.read(jobRepositoryProvider)),
      isTrue,
    );
  });

  test('ports can be overridden with fakes', () {
    final fake = MockJobRepository();
    final c = ProviderContainer.test(
      overrides: [jobRepositoryProvider.overrideWithValue(fake)],
    );
    expect(c.read(jobRepositoryProvider), same(fake));
  });

  group('read providers', () {
    ProviderContainer withCatalog() => ProviderContainer.test(
      overrides: [serviceCatalogProvider.overrideWithValue(_Catalog())],
    );

    test('jobServiceProvider, serviceOfferProvider and offersForServiceProvider read the catalog', () async {
      final c = withCatalog();
      expect((await c.read(jobServiceProvider('s1').future))?.title, 'Aseo');
      expect(await c.read(jobServiceProvider('nope').future), isNull);
      expect(
        (await c.read(serviceOfferProvider('o1').future))?.offerantId,
        'p1',
      );
      expect(await c.read(offersForServiceProvider('s1').future), hasLength(1));
    });

    test(
      'myJobsProvider and myServiceRequestsProvider list everything',
      () async {
        final c = ProviderContainer.test();
        expect(await c.read(myJobsProvider.future), isNotEmpty);
        expect(await c.read(myServiceRequestsProvider.future), isNotEmpty);
      },
    );
  });
}
