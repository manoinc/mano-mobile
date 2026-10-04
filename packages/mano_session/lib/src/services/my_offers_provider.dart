import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../marketplace_providers.dart';

/// The signed-in provider's own offers, deleted ones excluded.
final myOffersProvider = FutureProvider<List<ServiceOffer>>(
  (ref) => ref.watch(offerManagementProvider).myOffers(),
  retry: (_, _) => null,
);

// jobServiceProvider without auto-retry: a missing title just falls back to "Servicio".
final offeredServiceProvider = FutureProvider.family<JobService?, String>(
  (ref, id) => ref.watch(serviceCatalogProvider).service(id),
  retry: (_, _) => null,
);
