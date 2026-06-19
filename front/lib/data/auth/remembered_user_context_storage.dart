import 'dart:convert';

import 'package:amap_en_ligne/domain/auth/remembered_user_context.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesRememberedUserContextStore
    implements RememberedUserContextStore {
  SharedPreferencesRememberedUserContextStore({required this.prefs});

  static const _storageKey = 'auth.remembered_user.v1';

  final SharedPreferences prefs;

  @override
  Future<RememberedUserContext?> read({required String serverId}) async {
    final raw = prefs.getString(_storageKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      final context = RememberedUserContext.fromJson(json);
      if (context.serverId != serverId) return null;
      return context;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(RememberedUserContext context) async {
    await prefs.setString(_storageKey, jsonEncode(context.toJson()));
  }

  @override
  Future<void> clear() async {
    await prefs.remove(_storageKey);
  }
}
