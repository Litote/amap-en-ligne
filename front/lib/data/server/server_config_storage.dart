import 'dart:convert';

import 'package:amap_en_ligne/data/server/server_presets.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the selected `ServerConfig` as a serialized config blob so the app
/// can keep working when configuration eventually comes from discovery rather
/// than a static preset list.
///
/// The older id-only key is still read as a migration fallback for installs
/// that selected one of the historic in-binary presets.
class ServerConfigStorage {
  ServerConfigStorage({required this.prefs, List<ServerConfig>? presets})
    : presets = presets ?? serverPresets;

  static const _legacyIdStorageKey = 'server.selected.id.v1';
  static const _configStorageKey = 'server.selected.config.v2';

  final SharedPreferences prefs;
  final List<ServerConfig> presets;

  ServerConfig? read() {
    final encoded = prefs.getString(_configStorageKey);
    if (encoded != null) {
      try {
        return ServerConfig.fromJson(
          jsonDecode(encoded) as Map<String, dynamic>,
        );
      } on FormatException {
        // Fall through to legacy id migration or empty state.
      }
    }

    final id = prefs.getString(_legacyIdStorageKey);
    if (id == null) {
      return null;
    }
    for (final preset in presets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }

  Future<void> write(ServerConfig config) async {
    await prefs.setString(_configStorageKey, jsonEncode(config.toJson()));
    await prefs.remove(_legacyIdStorageKey);
  }

  Future<void> clear() async {
    await prefs.remove(_configStorageKey);
    await prefs.remove(_legacyIdStorageKey);
  }
}
