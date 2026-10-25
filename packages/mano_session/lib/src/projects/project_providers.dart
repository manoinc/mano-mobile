import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../offline_marketplace_provider.dart';
import '../session_providers.dart';

// One board, so offline the provider's quotes reach the requester's projects.
final _mockProjectBoardProvider = Provider((ref) => MockProjectBoard());

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? MockProjectRepository(ref.watch(_mockProjectBoardProvider))
      : GatewayProjectRepository(ref.watch(gatewayTransportProvider)),
);

final leadRepositoryProvider = Provider<LeadRepository>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? MockLeadRepository(ref.watch(_mockProjectBoardProvider))
      : GatewayLeadRepository(ref.watch(gatewayTransportProvider)),
);

/// The requester's projects, each with its quotes.
final myProjectsProvider = FutureProvider<List<Project>>(
  (ref) => ref.watch(projectRepositoryProvider).mine(),
);

/// Open projects for providers; null lists every category.
final openProjectsProvider = FutureProvider.family<List<Project>, String?>(
  (ref, category) =>
      ref.watch(leadRepositoryProvider).openProjects(category: category),
);

/// The provider's own quotes.
final myQuotesProvider = FutureProvider<List<Quote>>(
  (ref) => ref.watch(leadRepositoryProvider).myQuotes(),
);
