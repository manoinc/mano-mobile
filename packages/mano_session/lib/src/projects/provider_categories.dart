import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../marketplace_providers.dart';
import '../services/my_offers_provider.dart';

/// The canonical categories the professional offers, in the catalog's order.
final providerCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final offers = await ref.watch(myOffersProvider.future);
  final services = await Future.wait([
    for (final offer in offers)
      ref.watch(jobServiceProvider(offer.jobServiceId).future),
  ]);
  final ids = {
    for (final s in services)
      if (s != null) ServiceCategories.normalize(s.category),
  };
  return [
    for (final c in ServiceCategories.all)
      if (ids.contains(c.id)) c.id,
  ];
});
