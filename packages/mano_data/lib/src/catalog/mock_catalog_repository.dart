import 'package:mano_domain/mano_domain.dart';

final class MockCatalogRepository implements CatalogRepository {
  const MockCatalogRepository();

  static const List<ServiceCategory> _categories = ServiceCategories.all;

  static const List<ServiceListing> _listings = [
    ServiceListing(
      id: 'cleaning-1',
      title: 'Limpieza profunda de apartamento',
      categoryId: 'cleaning',
      professionalName: 'Carlos Mendoza',
      professionalPhotoUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
      photoUrl:
          'https://images.unsplash.com/photo-1646980241033-cd7abda2ee88?w=400&h=300&fit=crop',
      priceFromCents: 8000000,
      rating: 4.8,
      reviewCount: 24,
    ),
    ServiceListing(
      id: 'plumbing-1',
      title: 'Reparación de tuberías',
      categoryId: 'plumbing',
      professionalName: 'Juan García',
      professionalPhotoUrl: 'https://randomuser.me/api/portraits/men/45.jpg',
      photoUrl:
          'https://images.unsplash.com/photo-1676210134188-4c05dd172f89?w=400&h=300&fit=crop',
      priceFromCents: 7500000,
      rating: 4.5,
      reviewCount: 18,
    ),
    ServiceListing(
      id: 'electrical-1',
      title: 'Instalación de alambrado',
      categoryId: 'electrical',
      professionalName: 'Roberto López',
      professionalPhotoUrl: 'https://randomuser.me/api/portraits/men/68.jpg',
      photoUrl:
          'https://images.unsplash.com/photo-1751486289947-4f5f5961b3aa?w=400&h=300&fit=crop',
      priceFromCents: 9500000,
      rating: 4.9,
      reviewCount: 31,
    ),
    ServiceListing(
      id: 'painting-1',
      title: 'Pintura interior de casa',
      categoryId: 'painting',
      professionalName: 'Miguel Rodríguez',
      professionalPhotoUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
      photoUrl:
          'https://images.unsplash.com/photo-1688372199140-cade7ae820fe?w=400&h=300&fit=crop',
      priceFromCents: 6500000,
      rating: null,
      reviewCount: 5,
    ),
    ServiceListing(
      id: 'gardening-1',
      title: 'Mantenimiento de jardín',
      categoryId: 'gardening',
      professionalName: 'Diego Morales',
      professionalPhotoUrl: 'https://randomuser.me/api/portraits/men/51.jpg',
      photoUrl:
          'https://images.unsplash.com/photo-1621460248083-6271cc4437a8?w=400&h=300&fit=crop',
      priceFromCents: 5500000,
      rating: 4.6,
      reviewCount: 12,
    ),
    ServiceListing(
      id: 'cleaning-2',
      title: 'Limpieza de oficina',
      categoryId: 'cleaning',
      professionalName: 'Patricia Sánchez',
      professionalPhotoUrl: 'https://randomuser.me/api/portraits/women/65.jpg',
      photoUrl:
          'https://images.unsplash.com/photo-1627905646269-7f034dcc5738?w=400&h=300&fit=crop',
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
