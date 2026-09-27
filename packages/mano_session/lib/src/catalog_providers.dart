import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

/// The composition step that matters: an adapter bound to the domain's port.
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => const MockCatalogRepository(),
);

final serviceCategoriesProvider = FutureProvider<List<ServiceCategory>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);

final popularListingsProvider = FutureProvider<List<ServiceListing>>(
  (ref) => ref.watch(catalogRepositoryProvider).popularListings(),
);
