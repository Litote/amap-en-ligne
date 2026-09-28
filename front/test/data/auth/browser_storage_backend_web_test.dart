@TestOn('browser')
library;

import 'package:amap_en_ligne/data/auth/browser_storage_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('browser storage backend persists values in browser storage', () {
    final sessionStorage = createSessionBrowserStorageBackend();
    final localStorage = createLocalBrowserStorageBackend();
    const sessionKey = 'browser-storage-backend-web-test-session';
    const localKey = 'browser-storage-backend-web-test-local';

    sessionStorage.removeItem(sessionKey);
    localStorage.removeItem(localKey);

    sessionStorage.setItem(sessionKey, 'session-value');
    localStorage.setItem(localKey, 'local-value');

    expect(sessionStorage.getItem(sessionKey), 'session-value');
    expect(localStorage.getItem(localKey), 'local-value');

    sessionStorage.removeItem(sessionKey);
    localStorage.removeItem(localKey);

    expect(sessionStorage.getItem(sessionKey), isNull);
    expect(localStorage.getItem(localKey), isNull);
  });
}
