import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

ProviderContainer _container() => ProviderContainer.test(
  overrides: [
    manoConfigProvider.overrideWithValue(
      const ManoConfig(gatewayGraphQlUrl: 'http://gw/graphql'),
    ),
  ],
);

void main() {
  test('the catalog reads from the live gateway', () {
    expect(_container().read(serviceCatalogProvider), isA<GatewayServiceCatalog>());
  });

  test('stubbed backend ports default to mock adapters', () {
    final c = _container();
    expect(c.read(offerManagementProvider), isA<MockOfferManagement>());
    expect(c.read(serviceRequestRepositoryProvider), isA<MockServiceRequestRepository>());
    expect(c.read(jobRepositoryProvider), isA<MockJobRepository>());
    expect(c.read(availabilityRepositoryProvider), isA<MockAvailabilityRepository>());
    expect(c.read(chatRepositoryProvider), isA<MockChatRepository>());
    expect(c.read(providerOnboardingRepositoryProvider), isA<MockProviderOnboardingRepository>());
  });

  test('a mock keeps its state for the life of the container', () {
    final c = _container();
    expect(identical(c.read(jobRepositoryProvider), c.read(jobRepositoryProvider)), isTrue);
  });

  test('ports can be overridden with fakes', () {
    final fake = MockJobRepository();
    final c = ProviderContainer.test(overrides: [jobRepositoryProvider.overrideWithValue(fake)]);
    expect(c.read(jobRepositoryProvider), same(fake));
  });
}
