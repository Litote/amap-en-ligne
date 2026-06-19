import 'dart:convert';

import 'package:amap_en_ligne/data/auth/browser_storage_backend.dart';
import 'package:amap_en_ligne/data/auth/secure_storage_backend.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted shape of an authenticated session. Stored as a single JSON
/// blob. Used by both `GoTrueAuthService` and `CognitoAuthService` — the
/// wire is the same (`access_token` / `refresh_token` / `expires_at` /
/// `producer_id`).
///
/// Mobile persistence uses `flutter_secure_storage` (Keychain on iOS,
/// EncryptedSharedPreferences on Android). Web persistence uses
/// `sessionStorage` (temporary) or `localStorage` (durable, remember-me).
class StoredSession {
  const StoredSession({
    required this.producerId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory StoredSession.fromJson(Map<String, Object?> json) => StoredSession(
    producerId: (json['producer_id'] ?? json['producer_account_id'])! as String,
    accessToken: json['access_token']! as String,
    refreshToken: json['refresh_token']! as String,
    expiresAt: DateTime.parse(json['expires_at']! as String),
  );

  final String producerId;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  Map<String, Object?> toJson() => {
    'producer_id': producerId,
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toUtc().toIso8601String(),
  };
}

abstract class AuthTokenStorage {
  Future<StoredSession?> read();
  Future<void> write(StoredSession session, {bool? durable});
  Future<void> clear();
}

/// Legacy plain-text mobile storage. Kept only to support the one-time
/// migration path that moves existing sessions into [FlutterSecureStorage].
/// Web still uses it for its own legacy migration from pre-browser-storage
/// sessions.
class SharedPreferencesAuthTokenStorage implements AuthTokenStorage {
  SharedPreferencesAuthTokenStorage({required this.prefs});

  static const _storageKey = 'auth.session.v1';

  final SharedPreferences prefs;

  @override
  Future<StoredSession?> read() async {
    final raw = prefs.getString(_storageKey);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, Object?>;
    return StoredSession.fromJson(json);
  }

  @override
  Future<void> write(StoredSession session, {bool? durable}) async {
    await prefs.setString(_storageKey, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    await prefs.remove(_storageKey);
  }
}

/// [SecureStorageBackend] backed by [FlutterSecureStorage]: Keychain on iOS,
/// EncryptedSharedPreferences on Android.
class _FlutterSecureStorageBackend implements SecureStorageBackend {
  const _FlutterSecureStorageBackend(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// No-op backend used as the [AdaptiveAuthTokenStorage._secureStorage]
/// default when [AdaptiveAuthTokenStorage.isWeb] is true, so that the web
/// path never touches a native Keychain/EncryptedSharedPreferences.
class _NoopSecureStorageBackend implements SecureStorageBackend {
  const _NoopSecureStorageBackend();

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}

/// Selects the right persistence strategy at runtime:
///
/// * **Mobile (non-web):** [FlutterSecureStorage] — Keychain (iOS) or
///   EncryptedSharedPreferences (Android). On first read after upgrading from
///   a pre-secure-storage build, any session found in plain SharedPreferences
///   under the legacy key is automatically migrated and the old entry cleared.
///
/// * **Web:** `sessionStorage` for temporary sessions (default) or
///   `localStorage` for durable sessions (remember-me). A one-time migration
///   moves sessions that were written to SharedPreferences before the
///   browser-storage split.
class AdaptiveAuthTokenStorage implements AuthTokenStorage {
  AdaptiveAuthTokenStorage({
    required this.prefs,
    required this.isWeb,
    SecureStorageBackend? secureStorage,
    BrowserStorageBackend? sessionStorage,
    BrowserStorageBackend? localStorage,
  }) : _secureStorage =
           secureStorage ??
           (isWeb
               ? const _NoopSecureStorageBackend()
               : const _FlutterSecureStorageBackend(FlutterSecureStorage())),
       _prefsStorage = SharedPreferencesAuthTokenStorage(prefs: prefs),
       _sessionStorage = sessionStorage ?? createSessionBrowserStorageBackend(),
       _localStorage = localStorage ?? createLocalBrowserStorageBackend();

  // Shared by both mobile secure storage and the legacy SharedPreferences key
  // so that migration reads the same slot name from the old store.
  static const _mobileStorageKey = 'auth.session.v1';

  static const _webSessionStorageKey = 'auth.session.session.v1';
  static const _webLocalStorageKey = 'auth.session.local.v1';

  final SharedPreferences prefs;
  final bool isWeb;
  final SecureStorageBackend _secureStorage;
  final SharedPreferencesAuthTokenStorage _prefsStorage;
  final BrowserStorageBackend _sessionStorage;
  final BrowserStorageBackend _localStorage;

  bool? _lastWriteDurable;

  @override
  Future<StoredSession?> read() async {
    if (!isWeb) {
      // Normal path: read from secure storage.
      final secureRaw = await _secureStorage.read(_mobileStorageKey);
      if (secureRaw != null) return _decode(secureRaw);

      // One-time migration: existing sessions written to plain SharedPreferences
      // by earlier builds are transparently moved into secure storage so users
      // are not logged out after the upgrade.
      final legacy = await _prefsStorage.read();
      if (legacy == null) return null;
      await _secureStorage.write(
        _mobileStorageKey,
        jsonEncode(legacy.toJson()),
      );
      await _prefsStorage.clear();
      return legacy;
    }

    // Web: try sessionStorage (temporary) then localStorage (durable).
    final sessionRaw = _sessionStorage.getItem(_webSessionStorageKey);
    if (sessionRaw != null) {
      _lastWriteDurable = false;
      return _decode(sessionRaw);
    }

    final localRaw = _localStorage.getItem(_webLocalStorageKey);
    if (localRaw != null) {
      _lastWriteDurable = true;
      return _decode(localRaw);
    }

    // Web legacy migration from SharedPreferences (pre-browser-storage builds).
    final legacy = await _prefsStorage.read();
    if (legacy == null) return null;
    _lastWriteDurable = true;
    await write(legacy, durable: true);
    await _prefsStorage.clear();
    return legacy;
  }

  @override
  Future<void> write(StoredSession session, {bool? durable}) async {
    if (!isWeb) {
      await _secureStorage.write(
        _mobileStorageKey,
        jsonEncode(session.toJson()),
      );
      return;
    }

    final encoded = jsonEncode(session.toJson());
    final resolvedDurable = durable ?? _lastWriteDurable ?? false;
    _lastWriteDurable = resolvedDurable;

    if (resolvedDurable) {
      _localStorage.setItem(_webLocalStorageKey, encoded);
      _sessionStorage.removeItem(_webSessionStorageKey);
    } else {
      _sessionStorage.setItem(_webSessionStorageKey, encoded);
      _localStorage.removeItem(_webLocalStorageKey);
    }

    await _prefsStorage.clear();
  }

  @override
  Future<void> clear() async {
    if (!isWeb) {
      await _secureStorage.delete(_mobileStorageKey);
      // Belt-and-suspenders: also clear any leftover legacy SharedPreferences
      // entry that pre-dates the secure-storage migration.
      await _prefsStorage.clear();
      return;
    }

    _lastWriteDurable = null;
    _sessionStorage.removeItem(_webSessionStorageKey);
    _localStorage.removeItem(_webLocalStorageKey);
    await _prefsStorage.clear();
  }

  StoredSession _decode(String raw) {
    final json = jsonDecode(raw) as Map<String, Object?>;
    return StoredSession.fromJson(json);
  }
}
