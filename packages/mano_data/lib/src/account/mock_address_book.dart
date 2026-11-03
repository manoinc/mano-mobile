import 'package:mano_domain/mano_domain.dart';

/// In-memory [AddressBook]; starts empty.
final class MockAddressBook implements AddressBook {
  List<SavedAddress> _addresses = const [];
  int _nextId = 1;

  @override
  Future<List<SavedAddress>> list() async => _addresses;

  @override
  Future<Result<SavedAddress, DataFailure>> add(SavedAddress address) async {
    if (address.problems.isNotEmpty) return _rejected(address);
    final stored = address.copyWith(id: 'address-${_nextId++}');
    _addresses = withOneDefaultAddress([
      ..._addresses,
      stored.copyWith(isDefault: false),
    ], defaultId: address.isDefault ? stored.id : null);
    return Ok(_find(stored.id)!);
  }

  @override
  Future<Result<SavedAddress, DataFailure>> update(SavedAddress address) async {
    final current = _find(address.id);
    if (current == null) return const Err(DataNotFound());
    if (address.problems.isNotEmpty) return _rejected(address);
    _addresses = withOneDefaultAddress([
      for (final a in _addresses)
        a.id == address.id ? address.copyWith(isDefault: a.isDefault) : a,
    ]);
    return Ok(_find(address.id)!);
  }

  @override
  Future<Result<void, DataFailure>> remove(String id) async {
    if (_find(id) == null) return const Err(DataNotFound());
    _addresses = withOneDefaultAddress([
      for (final a in _addresses)
        if (a.id != id) a,
    ]);
    return const Ok(null);
  }

  @override
  Future<Result<void, DataFailure>> setDefault(String id) async {
    if (_find(id) == null) return const Err(DataNotFound());
    _addresses = withOneDefaultAddress(_addresses, defaultId: id);
    return const Ok(null);
  }

  SavedAddress? _find(String id) =>
      _addresses.where((a) => a.id == id).firstOrNull;

  Err<SavedAddress, DataFailure> _rejected(SavedAddress address) =>
      Err(DataRejected(reason: '${address.problems}'));
}
