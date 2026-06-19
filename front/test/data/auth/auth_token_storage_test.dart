import 'package:amap_en_ligne/data/auth/auth_token_storage.dart';
import 'package:amap_en_ligne/data/auth/browser_storage_backend.dart';
import 'package:amap_en_ligne/data/auth/browser_storage_backend_base.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBrowserStorageBackend implements BrowserStorageBackend {
  final Map<String, String> values = {};

  @override
  String? getItem(String key) => values[key];

  @override
  void removeItem(String key) {
    values.remove(key);
  }

  @override
  void setItem(String key, String value) {
    values[key] = value;
  }
}

StoredSession _session(String producerAccountId) => StoredSession(
  producerId: producerAccountId,
  accessToken: 'access-$producerAccountId',
  refreshToken: 'refresh-$producerAccountId',
  expiresAt: DateTime.utc(2030),
);

void main() {
  Future<SharedPreferences> prefs() async {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }

  test('mobile storage persists session in SharedPreferences', () async {
    final storage = AdaptiveAuthTokenStorage(
      prefs: await prefs(),
      isWeb: false,
    );

    await storage.write(_session('mobile-1'));

    final restored = await storage.read();
    expect(restored?.producerId, 'mobile-1');
  });

  test(
    'web storage writes temporary sessions to sessionStorage by default',
    () async {
      final sessionStorage = _FakeBrowserStorageBackend();
      final localStorage = _FakeBrowserStorageBackend();
      final storage = AdaptiveAuthTokenStorage(
        prefs: await prefs(),
        isWeb: true,
        sessionStorage: sessionStorage,
        localStorage: localStorage,
      );

      await storage.write(_session('web-temp'));

      expect(sessionStorage.values, isNotEmpty);
      expect(localStorage.values, isEmpty);
      expect((await storage.read())?.producerId, 'web-temp');
    },
  );

  test('web storage writes durable sessions to localStorage', () async {
    final sessionStorage = _FakeBrowserStorageBackend();
    final localStorage = _FakeBrowserStorageBackend();
    final storage = AdaptiveAuthTokenStorage(
      prefs: await prefs(),
      isWeb: true,
      sessionStorage: sessionStorage,
      localStorage: localStorage,
    );

    await storage.write(_session('web-durable'), durable: true);

    expect(localStorage.values, isNotEmpty);
    expect(sessionStorage.values, isEmpty);
    expect((await storage.read())?.producerId, 'web-durable');
  });

  test(
    'web storage preserves the current persistence mode across refresh writes',
    () async {
      final sessionStorage = _FakeBrowserStorageBackend();
      final localStorage = _FakeBrowserStorageBackend();
      final storage = AdaptiveAuthTokenStorage(
        prefs: await prefs(),
        isWeb: true,
        sessionStorage: sessionStorage,
        localStorage: localStorage,
      );

      await storage.write(_session('first'), durable: true);
      await storage.read();
      await storage.write(_session('refreshed'));

      expect(localStorage.values, isNotEmpty);
      expect(sessionStorage.values, isEmpty);
      expect((await storage.read())?.producerId, 'refreshed');
    },
  );

  test(
    'web storage migrates legacy SharedPreferences sessions to durable storage',
    () async {
      final legacySession = _session('legacy-1');
      SharedPreferences.setMockInitialValues({
        'auth.session.v1':
            '{"producer_account_id":"legacy-1","access_token":"access-legacy-1","refresh_token":"refresh-legacy-1","expires_at":"${legacySession.expiresAt.toIso8601String()}"}',
      });
      final sessionStorage = _FakeBrowserStorageBackend();
      final localStorage = _FakeBrowserStorageBackend();
      final storage = AdaptiveAuthTokenStorage(
        prefs: await SharedPreferences.getInstance(),
        isWeb: true,
        sessionStorage: sessionStorage,
        localStorage: localStorage,
      );

      final restored = await storage.read();

      expect(restored?.producerId, 'legacy-1');
      expect(localStorage.values, isNotEmpty);
      expect(sessionStorage.values, isEmpty);
    },
  );

  test('clear removes durable and temporary sessions', () async {
    final sessionStorage = _FakeBrowserStorageBackend();
    final localStorage = _FakeBrowserStorageBackend();
    final storage = AdaptiveAuthTokenStorage(
      prefs: await prefs(),
      isWeb: true,
      sessionStorage: sessionStorage,
      localStorage: localStorage,
    );
    await storage.write(_session('clear-me'), durable: true);

    await storage.clear();

    expect(await storage.read(), isNull);
    expect(localStorage.values, isEmpty);
    expect(sessionStorage.values, isEmpty);
  });
}
