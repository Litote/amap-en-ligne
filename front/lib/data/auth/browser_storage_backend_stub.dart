import 'package:amap_en_ligne/data/auth/browser_storage_backend_base.dart';

class _NoopBrowserStorageBackend implements BrowserStorageBackend {
  @override
  String? getItem(String key) => null;

  @override
  void removeItem(String key) {}

  @override
  void setItem(String key, String value) {}
}

BrowserStorageBackend createSessionBrowserStorageBackendImpl() =>
    _NoopBrowserStorageBackend();

BrowserStorageBackend createLocalBrowserStorageBackendImpl() =>
    _NoopBrowserStorageBackend();
