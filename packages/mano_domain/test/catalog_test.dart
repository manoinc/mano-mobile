import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ServiceCategory', () {
    test('two categories with different field values are unequal', () {
      final cat1 = ServiceCategory(
        id: 'cat1',
        label: 'Limpieza',
        iconKey: 'cleaning',
      );
      final cat2 = ServiceCategory(
        id: 'cat2',
        label: 'Plomería',
        iconKey: 'plumbing',
      );

      expect(cat1 == cat2, isFalse);
    });

    test('two categories with identical field values are equal and share a hashCode', () {
      final cat1 = ServiceCategory(
        id: 'cat1',
        label: 'Limpieza',
        iconKey: 'cleaning',
      );
      final cat2 = ServiceCategory(
        id: 'cat1',
        label: 'Limpieza',
        iconKey: 'cleaning',
      );

      expect(cat1 == cat2, isTrue);
      expect(cat1.hashCode == cat2.hashCode, isTrue);
    });

    test('toString is non-empty and mentions the id', () {
      final cat = ServiceCategory(
        id: 'cat1',
        label: 'Limpieza',
        iconKey: 'cleaning',
      );

      expect(cat.toString(), isNotEmpty);
      expect(cat.toString(), contains('cat1'));
    });
  });

  group('ServiceListing', () {
    test('two listings with different field values are unequal', () {
      final listing1 = ServiceListing(
        id: 'listing1',
        title: 'Servicio 1',
        categoryId: 'cat1',
        professionalName: 'Juan',
        professionalPhotoUrl: 'https://example.com/photo1.jpg',
        photoUrl: 'https://example.com/service1.jpg',
        priceFromCents: 10000,
        currency: 'COP',
        rating: 4.5,
        reviewCount: 10,
      );
      final listing2 = ServiceListing(
        id: 'listing2',
        title: 'Servicio 2',
        categoryId: 'cat2',
        professionalName: 'María',
        professionalPhotoUrl: 'https://example.com/photo2.jpg',
        photoUrl: 'https://example.com/service2.jpg',
        priceFromCents: 20000,
        currency: 'COP',
        rating: 4.0,
        reviewCount: 5,
      );

      expect(listing1 == listing2, isFalse);
    });

    test('two listings with identical field values are equal and share a hashCode', () {
      final listing1 = ServiceListing(
        id: 'listing1',
        title: 'Servicio 1',
        categoryId: 'cat1',
        professionalName: 'Juan',
        professionalPhotoUrl: 'https://example.com/photo1.jpg',
        photoUrl: 'https://example.com/service1.jpg',
        priceFromCents: 10000,
        currency: 'COP',
        rating: 4.5,
        reviewCount: 10,
      );
      final listing2 = ServiceListing(
        id: 'listing1',
        title: 'Servicio 1',
        categoryId: 'cat1',
        professionalName: 'Juan',
        professionalPhotoUrl: 'https://example.com/photo1.jpg',
        photoUrl: 'https://example.com/service1.jpg',
        priceFromCents: 10000,
        currency: 'COP',
        rating: 4.5,
        reviewCount: 10,
      );

      expect(listing1 == listing2, isTrue);
      expect(listing1.hashCode == listing2.hashCode, isTrue);
    });

    test('toString is non-empty and mentions the id', () {
      final listing = ServiceListing(
        id: 'listing1',
        title: 'Servicio 1',
        categoryId: 'cat1',
        professionalName: 'Juan',
        professionalPhotoUrl: 'https://example.com/photo1.jpg',
        photoUrl: 'https://example.com/service1.jpg',
        priceFromCents: 10000,
      );

      expect(listing.toString(), isNotEmpty);
      expect(listing.toString(), contains('listing1'));
    });
  });
}
