import 'dart:convert';

import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the selected `ServerConfig` as a serialized config blob so the app
/// can keep working when configuration eventually comes from discovery rather
/// than a static preset list.
class ServerConfigStorage {
  ServerConfigStorage({required this.prefs});

  static const _configStorageKey = 'server.selected.config.v2';

  final SharedPreferences prefs;

  ServerConfig? read() {
    final encoded = prefs.getString(_configStorageKey);
    if (encoded == null) return null;
    try {
      return ServerConfig.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> write(ServerConfig config) async {
    await prefs.setString(_configStorageKey, jsonEncode(config.toJson()));
  }

  Future<void> clear() async {
    await prefs.remove(_configStorageKey);
  }
}
