import 'service_category.dart';
import 'service_listing.dart';

abstract interface class CatalogRepository {
  Future<List<ServiceCategory>> categories();
  Future<List<ServiceListing>> popularListings();
}
