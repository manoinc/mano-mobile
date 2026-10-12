import 'package:mano_domain/mano_domain.dart';

/// One horizontal rail on the requester Home.
final class HomeSection {
  const HomeSection({
    required this.id,
    required this.title,
    required this.listings,
    this.categoryId,
  });

  final String id;
  final String title;
  final List<ServiceListing> listings;

  /// The category "Ver todo" filters by; null means all of them.
  final String? categoryId;
}

/// Derives the Home rails from the catalog: popular, top rated, then one per category.
List<HomeSection> homeSections(
  List<ServiceListing> listings, {
  int minCards = 4,
  int maxSections = 5,
}) {
  final topRated = [
    for (final l in listings)
      if (l.rating != null) l,
  ]..sort(_byRatingThenReviews);

  final sections = <HomeSection>[
    HomeSection(
      id: 'popular',
      title: 'Populares cerca de ti',
      listings: listings,
    ),
    HomeSection(
      id: 'top-rated',
      title: 'Mejor calificados',
      listings: topRated,
    ),
    for (final category in ServiceCategories.all)
      HomeSection(
        id: 'category-${category.id}',
        title: category.label,
        categoryId: category.id,
        listings: [
          for (final l in listings)
            if (l.categoryId == category.id) l,
        ],
      ),
  ];

  return [
    for (final s in sections)
      if (s.listings.length >= minCards) s,
  ].take(maxSections).toList();
}

int _byRatingThenReviews(ServiceListing a, ServiceListing b) {
  final byRating = b.rating!.compareTo(a.rating!);
  return byRating != 0 ? byRating : b.reviewCount.compareTo(a.reviewCount);
}
