import 'package:amap_en_ligne/data/auth/browser_storage_backend_base.dart';
import 'package:web/web.dart' as web;

class _HtmlBrowserStorageBackend implements BrowserStorageBackend {
  const _HtmlBrowserStorageBackend(this._storage);

  final web.Storage _storage;

  @override
  String? getItem(String key) => _storage.getItem(key);

  @override
  void removeItem(String key) {
    _storage.removeItem(key);
  }

  @override
  void setItem(String key, String value) {
    _storage.setItem(key, value);
  }
}

BrowserStorageBackend createSessionBrowserStorageBackendImpl() =>
    _HtmlBrowserStorageBackend(web.window.sessionStorage);

BrowserStorageBackend createLocalBrowserStorageBackendImpl() =>
    _HtmlBrowserStorageBackend(web.window.localStorage);
