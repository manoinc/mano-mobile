import 'job_service.dart';
import 'service_offer.dart';

/// The public catalog: what can be hired and who offers it.
abstract interface class ServiceCatalog {
  Future<List<JobService>> search({String? category, String? text});

  /// Null when no such service exists.
  Future<JobService?> service(String id);

  /// Null when no such offer exists.
  Future<ServiceOffer?> offer(String id);

  /// Active offers only.
  Future<List<ServiceOffer>> offersFor(String jobServiceId);
}
