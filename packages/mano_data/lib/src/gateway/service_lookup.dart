import 'package:mano_domain/mano_domain.dart';

/// Looks a job service up once per id, so lists don't refetch the same title.
final class ServiceLookup {
  ServiceLookup(this._catalog);

  final ServiceCatalog _catalog;
  final _cache = <String, Future<JobService?>>{};

  /// Null when the catalog has no such service; a failed lookup is retried next time.
  Future<JobService?> call(String id) => _cache[id] ??= _catalog
      .service(id)
      .catchError((Object error, StackTrace stack) {
        _cache.remove(id);
        Error.throwWithStackTrace(error, stack);
      });
}
