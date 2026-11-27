import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the in-app dark mode choice lives between runs.
abstract interface class AppearanceStore {
  /// Whether the user turned dark mode on; `false` when never set.
  Future<bool> readDark();

  Future<void> writeDark(bool dark);
}

/// [AppearanceStore] on the storage the app already ships for its token.
final class SecureAppearanceStore implements AppearanceStore {
  const SecureAppearanceStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _key = 'mano.appearance.dark';

  @override
  Future<bool> readDark() async => await _storage.read(key: _key) == 'true';

  @override
  Future<void> writeDark(bool dark) =>
      _storage.write(key: _key, value: '$dark');
}

/// An in-memory [AppearanceStore] for tests.
final class InMemoryAppearanceStore implements AppearanceStore {
  // ignore: prefer_initializing_formals
  InMemoryAppearanceStore({bool dark = false}) : _dark = dark;

  bool _dark;

  @override
  Future<bool> readDark() async => _dark;

  @override
  Future<void> writeDark(bool dark) async => _dark = dark;
}
