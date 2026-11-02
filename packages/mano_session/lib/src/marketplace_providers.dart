import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import 'conversation_providers.dart';
import 'gateway_subscription_provider.dart';
import 'media/media_providers.dart';
import 'offline_marketplace_provider.dart';
import 'session_notifier.dart';
import 'session_providers.dart';

// One provider per marketplace port: the gateway adapter, or its mock when offline (docs/develop/backend-contract.md).

final serviceCatalogProvider = Provider<ServiceCatalog>(
  (ref) => GatewayServiceCatalog(ref.watch(gatewayTransportProvider)),
);

final offerManagementProvider = Provider<OfferManagement>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? MockOfferManagement()
      : GatewayOfferManagement(ref.watch(gatewayTransportProvider)),
);

// Offline mocks built together so accepting a request schedules a job and rebooking files a request.
final _mockWorkStoresProvider = Provider((ref) {
  late final MockJobRepository jobs;
  final requests = MockServiceRequestRepository(
    onAccepted: (request) => jobs.addFromRequest(request),
  );
  jobs = MockJobRepository(requests: requests);
  return (requests: requests, jobs: jobs);
});

final serviceRequestRepositoryProvider = Provider<ServiceRequestRepository>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? ref.watch(_mockWorkStoresProvider).requests
      : GatewayServiceRequestRepository(
          ref.watch(gatewayTransportProvider),
          ref.watch(serviceCatalogProvider),
        ),
);

final jobRepositoryProvider = Provider<JobRepository>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? ref.watch(_mockWorkStoresProvider).jobs
      : GatewayJobRepository(
          ref.watch(gatewayTransportProvider),
          ref.watch(serviceCatalogProvider),
        ),
);

final availabilityRepositoryProvider = Provider<AvailabilityRepository>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? MockAvailabilityRepository()
      : GatewayAvailabilityRepository(ref.watch(gatewayTransportProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (!ref.watch(offlineMarketplaceProvider)) {
    return GatewayChatRepository(
      ref.watch(gatewayTransportProvider),
      subscribe: ref.watch(gatewaySubscriptionClientProvider).subscribe,
      viewerId: () => ref.read(currentUserProvider)?.subject,
    );
  }
  // Shares the mock inbox so reads and sends show up in the conversation list.
  final inbox = ref.watch(conversationRepositoryProvider);
  return MockChatRepository(
    replyDelay: const Duration(seconds: 2),
    conversations: inbox is MockConversationRepository ? inbox : null,
    media: ref.watch(mockMediaLibraryProvider),
  );
});

final providerOnboardingRepositoryProvider =
    Provider<ProviderOnboardingRepository>(
      (ref) => MockProviderOnboardingRepository(),
    );

// Shared reads. Mutating screens invalidate these so every list stays current.

final jobServiceProvider = FutureProvider.family<JobService?, String>(
  (ref, id) => ref.watch(serviceCatalogProvider).service(id),
);

final serviceOfferProvider = FutureProvider.family<ServiceOffer?, String>(
  (ref, id) => ref.watch(serviceCatalogProvider).offer(id),
);

final offersForServiceProvider =
    FutureProvider.family<List<ServiceOffer>, String>(
      (ref, serviceId) =>
          ref.watch(serviceCatalogProvider).offersFor(serviceId),
    );

final myJobsProvider = FutureProvider<List<Job>>(
  (ref) => ref.watch(jobRepositoryProvider).mine(),
);

final myServiceRequestsProvider = FutureProvider<List<ServiceRequest>>(
  (ref) => ref.watch(serviceRequestRepositoryProvider).mine(),
);
