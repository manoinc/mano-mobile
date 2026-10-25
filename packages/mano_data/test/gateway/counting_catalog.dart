import 'package:mano_domain/mano_domain.dart';

/// A [ServiceCatalog] that knows one service and counts its lookups.
final class CountingCatalog implements ServiceCatalog {
  CountingCatalog({this.failNext = false});

  static const plumbing = JobService(
    id: 's1',
    category: 'plumbing',
    title: 'Reparación de fugas',
    description: '',
  );

  final lookups = <String>[];
  bool failNext;

  @override
  Future<JobService?> service(String id) async {
    lookups.add(id);
    if (failNext) {
      failNext = false;
      throw StateError('catalog down');
    }
    return id == plumbing.id ? plumbing : null;
  }

  @override
  Future<List<JobService>> search({String? category, String? text}) =>
      throw UnimplementedError();

  @override
  Future<ServiceOffer?> offer(String id) => throw UnimplementedError();

  @override
  Future<List<ServiceOffer>> offersFor(String jobServiceId) =>
      throw UnimplementedError();
}
