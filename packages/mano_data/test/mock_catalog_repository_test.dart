import 'package:mano_data/src/catalog/mock_catalog_repository.dart';
import 'package:test/test.dart';

void main() {
  group('MockCatalogRepository', () {
    late MockCatalogRepository repository;

    setUp(() {
      repository = const MockCatalogRepository();
    });

    test('categories() returns a non-empty list', () async {
      final categories = await repository.categories();
      expect(categories, isNotEmpty);
    });

    test('popularListings() returns a non-empty list', () async {
      final listings = await repository.popularListings();
      expect(listings, isNotEmpty);
    });

    test(
      'every listing categoryId matches a category id',
      () async {
        final categories = await repository.categories();
        final listings = await repository.popularListings();

        final categoryIds = {for (final c in categories) c.id};

        for (final listing in listings) {
          expect(categoryIds.contains(listing.categoryId), isTrue,
              reason: 'Listing $listing has unknown categoryId: ${listing.categoryId}');
        }
      },
    );

    test('every photoUrl and professionalPhotoUrl starts with https://', () async {
      final listings = await repository.popularListings();

      for (final listing in listings) {
        expect(listing.photoUrl.startsWith('https://'), isTrue,
            reason: 'Listing $listing has invalid photoUrl: ${listing.photoUrl}');
        expect(listing.professionalPhotoUrl.startsWith('https://'), isTrue,
            reason: 'Listing $listing has invalid professionalPhotoUrl: ${listing.professionalPhotoUrl}');
      }
    });
  });
}
