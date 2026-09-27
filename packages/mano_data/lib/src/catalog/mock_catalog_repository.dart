import 'package:mano_domain/mano_domain.dart';

final class MockCatalogRepository implements CatalogRepository {
  const MockCatalogRepository();

  static const List<ServiceCategory> _categories = [
    ServiceCategory(
      id: 'cleaning',
      label: 'Limpieza',
      iconKey: 'cleaning',
    ),
    ServiceCategory(
      id: 'plumbing',
      label: 'Plomería',
      iconKey: 'plumbing',
    ),
    ServiceCategory(
      id: 'electrical',
      label: 'Electricidad',
      iconKey: 'electrical',
    ),
    ServiceCategory(
      id: 'painting',
      label: 'Pintura',
      iconKey: 'painting',
    ),
    ServiceCategory(
      id: 'gardening',
      label: 'Jardinería',
      iconKey: 'gardening',
    ),
  ];

  static const List<ServiceListing> _listings = [
    ServiceListing(
      id: 'cleaning-1',
      title: 'Limpieza profunda de apartamento',
      categoryId: 'cleaning',
      professionalName: 'Carlos Mendoza',
      professionalPhotoUrl: 'https://i.pravatar.cc/150?u=carlos-mendoza',
      photoUrl: 'https://picsum.photos/seed/mano-cleaning-1/400/300',
      priceFromCents: 8000000,
      rating: 4.8,
      reviewCount: 24,
    ),
    ServiceListing(
      id: 'plumbing-1',
      title: 'Reparación de tuberías',
      categoryId: 'plumbing',
      professionalName: 'Juan García',
      professionalPhotoUrl: 'https://i.pravatar.cc/150?u=juan-garcia',
      photoUrl: 'https://picsum.photos/seed/mano-plumbing-1/400/300',
      priceFromCents: 7500000,
      rating: 4.5,
      reviewCount: 18,
    ),
    ServiceListing(
      id: 'electrical-1',
      title: 'Instalación de alambrado',
      categoryId: 'electrical',
      professionalName: 'Roberto López',
      professionalPhotoUrl: 'https://i.pravatar.cc/150?u=roberto-lopez',
      photoUrl: 'https://picsum.photos/seed/mano-electrical-1/400/300',
      priceFromCents: 9500000,
      rating: 4.9,
      reviewCount: 31,
    ),
    ServiceListing(
      id: 'painting-1',
      title: 'Pintura interior de casa',
      categoryId: 'painting',
      professionalName: 'Miguel Rodríguez',
      professionalPhotoUrl: 'https://i.pravatar.cc/150?u=miguel-rodriguez',
      photoUrl: 'https://picsum.photos/seed/mano-painting-1/400/300',
      priceFromCents: 6500000,
      rating: null,
      reviewCount: 5,
    ),
    ServiceListing(
      id: 'gardening-1',
      title: 'Mantenimiento de jardín',
      categoryId: 'gardening',
      professionalName: 'Diego Morales',
      professionalPhotoUrl: 'https://i.pravatar.cc/150?u=diego-morales',
      photoUrl: 'https://picsum.photos/seed/mano-gardening-1/400/300',
      priceFromCents: 5500000,
      rating: 4.6,
      reviewCount: 12,
    ),
    ServiceListing(
      id: 'cleaning-2',
      title: 'Limpieza de oficina',
      categoryId: 'cleaning',
      professionalName: 'Patricia Sánchez',
      professionalPhotoUrl: 'https://i.pravatar.cc/150?u=patricia-sanchez',
      photoUrl: 'https://picsum.photos/seed/mano-cleaning-2/400/300',
      priceFromCents: 10000000,
      rating: null,
      reviewCount: 8,
    ),
  ];

  @override
  Future<List<ServiceCategory>> categories() async => _categories;

  @override
  Future<List<ServiceListing>> popularListings() async => _listings;
}
