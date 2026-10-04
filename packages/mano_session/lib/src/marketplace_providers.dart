import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import 'session_providers.dart';

// One provider per marketplace port. The catalog is live on the gateway; the
// rest are stubs there, so they default to in-memory mocks (docs/backend-contract.md).

final serviceCatalogProvider = Provider<ServiceCatalog>(
  (ref) => GatewayServiceCatalog(ref.watch(gatewayTransportProvider)),
);

final offerManagementProvider = Provider<OfferManagement>(
  (ref) => MockOfferManagement(),
);

final serviceRequestRepositoryProvider = Provider<ServiceRequestRepository>(
  (ref) => MockServiceRequestRepository(),
);

final jobRepositoryProvider = Provider<JobRepository>(
  (ref) => MockJobRepository(),
);

final availabilityRepositoryProvider = Provider<AvailabilityRepository>(
  (ref) => MockAvailabilityRepository(),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => MockChatRepository(replyDelay: const Duration(seconds: 2)),
);

final providerOnboardingRepositoryProvider =
    Provider<ProviderOnboardingRepository>(
      (ref) => MockProviderOnboardingRepository(),
    );
