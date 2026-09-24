import 'package:amap_en_ligne/data/auth/auth_token_storage.dart';
import 'package:amap_en_ligne/data/auth/browser_storage_backend.dart';
import 'package:amap_en_ligne/data/auth/browser_storage_backend_base.dart';
import 'package:amap_en_ligne/data/auth/secure_storage_backend.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('mobile storage', () {
    test('persists session in secure storage', () async {
      final secureStorage = _FakeSecureStorageBackend();
      final storage = AdaptiveAuthTokenStorage(
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
      final storage = AdaptiveAuthTokenStorage(
        isWeb: false,
        secureStorage: secureStorage,
      );

      await storage.write(_session('mobile-check'));

      expect(secureStorage.values, isNotEmpty);
    });

    test(
      'clear removes session from secure storage',
      () async {
        final secureStorage = _FakeSecureStorageBackend();
        final storage = AdaptiveAuthTokenStorage(
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

    test('clear removes durable and temporary sessions', () async {
      final sessionStorage = _FakeBrowserStorageBackend();
      final localStorage = _FakeBrowserStorageBackend();
      final storage = AdaptiveAuthTokenStorage(
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
