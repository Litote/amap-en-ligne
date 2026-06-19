import 'dart:convert';

import 'package:amap_en_ligne/data/auth/browser_storage_backend.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted shape of an authenticated session. Stored as a single JSON
/// blob under [_storageKey] in `SharedPreferences`. Used by both
/// `GoTrueAuthService` and `CognitoAuthService` — the wire is the same
/// (`access_token` / `refresh_token` / `expires_at` / `producer_id`).
/// We do not yet use `flutter_secure_storage` — to add when the threat
/// model demands it (jailbroken / multi-user shared device). For now the
/// offline cache in drift already lives unencrypted in app sandbox
/// storage, so this is the same trust boundary.
class StoredSession {
  const StoredSession({
    required this.producerId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

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

  factory StoredSession.fromJson(Map<String, Object?> json) => StoredSession(
    producerId: (json['producer_id'] ?? json['producer_account_id'])! as String,
    accessToken: json['access_token']! as String,
    refreshToken: json['refresh_token']! as String,
    expiresAt: DateTime.parse(json['expires_at']! as String),
  );
}

abstract class AuthTokenStorage {
  Future<StoredSession?> read();
  Future<void> write(StoredSession session, {bool? durable});
  Future<void> clear();
}

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

class AdaptiveAuthTokenStorage implements AuthTokenStorage {
  AdaptiveAuthTokenStorage({
    required this.prefs,
    required this.isWeb,
    BrowserStorageBackend? sessionStorage,
    BrowserStorageBackend? localStorage,
  }) : _prefsStorage = SharedPreferencesAuthTokenStorage(prefs: prefs),
       _sessionStorage = sessionStorage ?? createSessionBrowserStorageBackend(),
       _localStorage = localStorage ?? createLocalBrowserStorageBackend();

  static const _webSessionStorageKey = 'auth.session.session.v1';
  static const _webLocalStorageKey = 'auth.session.local.v1';

  final SharedPreferences prefs;
  final bool isWeb;
  final SharedPreferencesAuthTokenStorage _prefsStorage;
  final BrowserStorageBackend _sessionStorage;
  final BrowserStorageBackend _localStorage;

  bool? _lastWriteDurable;

  @override
  Future<StoredSession?> read() async {
    if (!isWeb) return _prefsStorage.read();

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
      await _prefsStorage.write(session, durable: durable);
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
