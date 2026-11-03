import 'package:mano_domain/mano_domain.dart';

/// In-memory [PaymentMethods]; keeps display data only, starts empty.
final class MockPaymentMethods implements PaymentMethods {
  MockPaymentMethods({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  List<PaymentMethod> _methods = const [];
  int _nextId = 1;

  @override
  Future<List<PaymentMethod>> list() async => _methods;

  @override
  Future<Result<PaymentMethod, DataFailure>> add(
    NewPaymentMethod method,
  ) async {
    final problems = method.problems(_now());
    if (problems.isNotEmpty) return Err(DataRejected(reason: '$problems'));
    final stored = method.storedAs('payment-${_nextId++}');
    _methods = withOneDefaultMethod([..._methods, stored]);
    return Ok(_find(stored.id)!);
  }

  @override
  Future<Result<void, DataFailure>> remove(String id) async {
    if (_find(id) == null) return const Err(DataNotFound());
    _methods = withOneDefaultMethod([
      for (final m in _methods)
        if (m.id != id) m,
    ]);
    return const Ok(null);
  }

  @override
  Future<Result<void, DataFailure>> setDefault(String id) async {
    if (_find(id) == null) return const Err(DataNotFound());
    _methods = withOneDefaultMethod(_methods, defaultId: id);
    return const Ok(null);
  }

  PaymentMethod? _find(String id) =>
      _methods.where((m) => m.id == id).firstOrNull;
}
