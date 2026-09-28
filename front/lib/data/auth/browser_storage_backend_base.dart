abstract class BrowserStorageBackend {
  String? getItem(String key);
  void setItem(String key, String value);
  void removeItem(String key);
}
