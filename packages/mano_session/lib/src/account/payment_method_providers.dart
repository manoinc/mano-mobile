import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

// Mock: billing is not on the gateway, so nothing is tokenised or charged yet.
final paymentMethodsProvider = Provider<PaymentMethods>(
  (ref) => MockPaymentMethods(),
);

final savedPaymentMethodsProvider = FutureProvider<List<PaymentMethod>>(
  (ref) => ref.watch(paymentMethodsProvider).list(),
);

/// Payment method writes; each success refreshes the list.
final class PaymentMethodActions extends Notifier<void> {
  @override
  void build() {}

  PaymentMethods get _methods => ref.read(paymentMethodsProvider);

  Future<Result<PaymentMethod, DataFailure>> add(NewPaymentMethod method) =>
      _refreshing(_methods.add(method));

  Future<Result<void, DataFailure>> remove(String id) =>
      _refreshing(_methods.remove(id));

  Future<Result<void, DataFailure>> setDefault(String id) =>
      _refreshing(_methods.setDefault(id));

  Future<Result<T, DataFailure>> _refreshing<T>(
    Future<Result<T, DataFailure>> write,
  ) async {
    final result = await write;
    if (result.isOk) ref.invalidate(savedPaymentMethodsProvider);
    return result;
  }
}

final paymentMethodActionsProvider =
    NotifierProvider<PaymentMethodActions, void>(PaymentMethodActions.new);
