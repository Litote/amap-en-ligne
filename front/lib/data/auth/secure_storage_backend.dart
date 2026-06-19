import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    show FlutterSecureStorage;

/// Async key-value store interface for mobile token persistence.
/// The production implementation wraps [FlutterSecureStorage] (Keychain on
/// iOS, EncryptedSharedPreferences on Android). Tests inject an in-memory fake.
abstract class SecureStorageBackend {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}
