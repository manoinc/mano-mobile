import '../catalog/service_categories.dart';

/// What a lead costs a provider in coins; bigger jobs cost more.
abstract final class LeadPricing {
  static const defaultCost = 2;

  static const _costs = {
    ServiceCategories.cleaning: 2,
    ServiceCategories.gardening: 2,
    ServiceCategories.plumbing: 3,
    ServiceCategories.electrical: 3,
    ServiceCategories.painting: 4,
  };

  static int costFor(String category) =>
      _costs[ServiceCategories.normalize(category)] ?? defaultCost;
}
