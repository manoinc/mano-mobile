import '../catalog/service_categories.dart';

/// What a project lead costs in coins, by category; billing's `leadPrices`.
final class LeadPricing {
  const LeadPricing({required this.defaultCoins, this.prices = const {}});

  /// What a category without its own price costs.
  final int defaultCoins;

  /// Keyed by canonical category id.
  final Map<String, int> prices;

  /// The prices billing is seeded with; offline and tests use them.
  static const placeholder = LeadPricing(
    defaultCoins: 2,
    prices: {
      ServiceCategories.cleaning: 2,
      ServiceCategories.gardening: 2,
      ServiceCategories.plumbing: 3,
      ServiceCategories.electrical: 3,
      ServiceCategories.painting: 4,
    },
  );

  int costFor(String category) =>
      prices[ServiceCategories.normalize(category)] ?? defaultCoins;

  @override
  bool operator ==(Object other) =>
      other is LeadPricing &&
      other.defaultCoins == defaultCoins &&
      other.prices.length == prices.length &&
      prices.entries.every((e) => other.prices[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    defaultCoins,
    Object.hashAllUnordered(
      prices.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}
