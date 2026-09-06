import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the refresh token lives between runs of the app.
///
/// Behind an interface so a repository can be tested with an in-memory
/// implementation, and so the storage mechanism can change without anything
/// above noticing.
abstract interface class TokenStore {
  /// The stored refresh token, or `null` if nobody is signed in.
  Future<String?> read();

  /// Persists [refreshToken], replacing anything already there.
  Future<void> write(String refreshToken);

  /// Forgets the stored token.
  Future<void> clear();
}

/// [TokenStore] backed by the platform keystore.
///
/// A refresh token is a long-lived credential: it can be exchanged for access
/// tokens until it is revoked. That rules out `SharedPreferences`, which is
/// plain XML readable by anything with access to the app's data directory on a
/// rooted device.
final class SecureTokenStore implements TokenStore {
  const SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _key = 'mano.refresh_token';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String refreshToken) =>
      _storage.write(key: _key, value: refreshToken);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// An in-memory [TokenStore] for tests.
final class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore([this._token]);

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String refreshToken) async => _token = refreshToken;

  @override
  Future<void> clear() async => _token = null;
}
