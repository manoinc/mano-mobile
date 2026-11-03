import '../result.dart';
import '../shared/data_failure.dart';
import 'saved_address.dart';

/// The Solicitante's saved addresses; one is always the default while any exist.
abstract interface class AddressBook {
  /// The default first.
  Future<List<SavedAddress>> list();

  /// Stores [address] under a new id; the first one becomes the default.
  Future<Result<SavedAddress, DataFailure>> add(SavedAddress address);

  Future<Result<SavedAddress, DataFailure>> update(SavedAddress address);

  /// Removing the default promotes the next address.
  Future<Result<void, DataFailure>> remove(String id);

  Future<Result<void, DataFailure>> setDefault(String id);
}
