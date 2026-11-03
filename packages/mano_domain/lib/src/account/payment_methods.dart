import '../result.dart';
import '../shared/data_failure.dart';
import 'payment_method.dart';

/// The Solicitante's saved ways to pay; one is always the default while any exist.
abstract interface class PaymentMethods {
  /// The default first.
  Future<List<PaymentMethod>> list();

  /// Keeps display data only; the first one becomes the default.
  Future<Result<PaymentMethod, DataFailure>> add(NewPaymentMethod method);

  /// Removing the default promotes the next method.
  Future<Result<void, DataFailure>> remove(String id);

  Future<Result<void, DataFailure>> setDefault(String id);
}
