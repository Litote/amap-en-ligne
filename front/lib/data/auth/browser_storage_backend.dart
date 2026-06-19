import 'package:amap_en_ligne/data/auth/browser_storage_backend_base.dart';
import 'package:amap_en_ligne/data/auth/browser_storage_backend_stub.dart'
    if (dart.library.js_interop) 'package:amap_en_ligne/data/auth/browser_storage_backend_web.dart';

export 'package:amap_en_ligne/data/auth/browser_storage_backend_base.dart';

BrowserStorageBackend createSessionBrowserStorageBackend() =>
    createSessionBrowserStorageBackendImpl();

BrowserStorageBackend createLocalBrowserStorageBackend() =>
    createLocalBrowserStorageBackendImpl();
