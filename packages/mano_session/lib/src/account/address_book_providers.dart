import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

// Mock: the gateway has no saved-addresses operations yet.
final addressBookProvider = Provider<AddressBook>((ref) => MockAddressBook());

final savedAddressesProvider = FutureProvider<List<SavedAddress>>(
  (ref) => ref.watch(addressBookProvider).list(),
);

/// The address work goes to by default, or null while the book is empty.
final defaultAddressProvider = FutureProvider<SavedAddress?>((ref) async {
  final addresses = await ref.watch(savedAddressesProvider.future);
  return addresses.where((a) => a.isDefault).firstOrNull;
});

/// Address book writes; each success refreshes the list.
final class AddressBookActions extends Notifier<void> {
  @override
  void build() {}

  AddressBook get _book => ref.read(addressBookProvider);

  Future<Result<SavedAddress, DataFailure>> add(SavedAddress address) =>
      _refreshing(_book.add(address));

  Future<Result<SavedAddress, DataFailure>> update(SavedAddress address) =>
      _refreshing(_book.update(address));

  Future<Result<void, DataFailure>> remove(String id) =>
      _refreshing(_book.remove(id));

  Future<Result<void, DataFailure>> setDefault(String id) =>
      _refreshing(_book.setDefault(id));

  Future<Result<T, DataFailure>> _refreshing<T>(
    Future<Result<T, DataFailure>> write,
  ) async {
    final result = await write;
    if (result.isOk) ref.invalidate(savedAddressesProvider);
    return result;
  }
}

final addressBookActionsProvider = NotifierProvider<AddressBookActions, void>(
  AddressBookActions.new,
);
