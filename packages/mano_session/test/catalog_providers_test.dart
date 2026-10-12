import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

/// Tests the catalog providers with a fake repository and nothing else.

final class _FakeCatalogRepository implements CatalogRepository {
  _FakeCatalogRepository({
    this.onCategories,
    this.onPopularListings,
  });

  final Future<List<ServiceCategory>> Function()? onCategories;
  final Future<List<ServiceListing>> Function()? onPopularListings;

  @override
  Future<List<ServiceCategory>> categories() async =>
      onCategories?.call() ?? const [];

  @override
  Future<List<ServiceListing>> popularListings() async =>
      onPopularListings?.call() ?? const [];
}

const _category = ServiceCategory(
  id: 'test-category',
  label: 'Test Category',
  iconKey: 'test-icon',
);

const _listing = ServiceListing(
  id: 'test-listing',
  title: 'Test Listing',
  categoryId: 'test-category',
  professionalName: 'Test Professional',
  professionalPhotoUrl: 'https://example.com/photo.jpg',
  photoUrl: 'https://example.com/service.jpg',
  priceFromCents: 100000,
  rating: 4.5,
  reviewCount: 10,
);

ProviderContainer containerWith(CatalogRepository repository) {
  final container = ProviderContainer.test(
    overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
  );
  return container;
}

void main() {
  test('serviceCategoriesProvider resolves to the fake categories list', () async {
    final container = containerWith(
      _FakeCatalogRepository(
        onCategories: () async => const [_category],
      ),
    );

    final categories = await container.read(serviceCategoriesProvider.future);

    expect(categories, [_category]);
  });

  test('serviceCategoriesProvider resolves to empty list when overridden', () async {
    final container = containerWith(
      _FakeCatalogRepository(onCategories: () async => []),
    );

    final categories = await container.read(serviceCategoriesProvider.future);

    expect(categories, isEmpty);
  });

  test('popularListingsProvider resolves to the fake listings list', () async {
    final container = containerWith(
      _FakeCatalogRepository(
        onPopularListings: () async => const [_listing],
      ),
    );

    final listings = await container.read(popularListingsProvider.future);

    expect(listings, [_listing]);
  });

  test('popularListingsProvider resolves to empty list when overridden', () async {
    final container = containerWith(
      _FakeCatalogRepository(onPopularListings: () async => []),
    );

    final listings = await container.read(popularListingsProvider.future);

    expect(listings, isEmpty);
  });
}
