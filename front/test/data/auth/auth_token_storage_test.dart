import 'package:amap_en_ligne/data/auth/auth_token_storage.dart';
import 'package:amap_en_ligne/data/auth/browser_storage_backend.dart';
import 'package:amap_en_ligne/data/auth/browser_storage_backend_base.dart';
import 'package:amap_en_ligne/data/auth/secure_storage_backend.dart';
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

class _FakeSecureStorageBackend implements SecureStorageBackend {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
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

  group('mobile storage', () {
    test('persists session in secure storage', () async {
      final secureStorage = _FakeSecureStorageBackend();
      final storage = AdaptiveAuthTokenStorage(
        prefs: await prefs(),
        isWeb: false,
        secureStorage: secureStorage,
      );

      await storage.write(_session('mobile-1'));

      final restored = await storage.read();
      expect(restored?.producerId, 'mobile-1');
      expect(secureStorage.values, isNotEmpty);
    });

    test('does not write to SharedPreferences on write', () async {
      final secureStorage = _FakeSecureStorageBackend();
      final p = await prefs();
      final storage = AdaptiveAuthTokenStorage(
        prefs: p,
        isWeb: false,
        secureStorage: secureStorage,
      );

      await storage.write(_session('mobile-check'));

      expect(p.getString('auth.session.v1'), isNull);
      expect(secureStorage.values, isNotEmpty);
    });

    test('migrates legacy SharedPreferences session to secure storage', () async {
      final legacySession = _session('legacy-mobile');
      SharedPreferences.setMockInitialValues({
        'auth.session.v1':
            '{"producer_account_id":"legacy-mobile","access_token":"access-legacy-mobile","refresh_token":"refresh-legacy-mobile","expires_at":"${legacySession.expiresAt.toIso8601String()}"}',
      });
      final secureStorage = _FakeSecureStorageBackend();
      final storage = AdaptiveAuthTokenStorage(
        prefs: await SharedPreferences.getInstance(),
        isWeb: false,
        secureStorage: secureStorage,
      );

      final restored = await storage.read();

      expect(restored?.producerId, 'legacy-mobile');
      // Session was moved into secure storage.
      expect(secureStorage.values, isNotEmpty);
      // Legacy SharedPreferences entry was cleared.
      final p = await SharedPreferences.getInstance();
      expect(p.getString('auth.session.v1'), isNull);
    });

    test(
      'clear removes session from secure storage and legacy prefs',
      () async {
        final secureStorage = _FakeSecureStorageBackend();
        final storage = AdaptiveAuthTokenStorage(
          prefs: await prefs(),
          isWeb: false,
          secureStorage: secureStorage,
        );
        await storage.write(_session('clear-mobile'));

        await storage.clear();

        expect(await storage.read(), isNull);
        expect(secureStorage.values, isEmpty);
      },
    );
  });

  group('web storage', () {
    test('writes temporary sessions to sessionStorage by default', () async {
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
    });

    test('writes durable sessions to localStorage', () async {
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
      'preserves the current persistence mode across refresh writes',
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
      'migrates legacy SharedPreferences sessions to durable storage',
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
  });
}
