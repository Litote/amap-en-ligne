import 'package:amap_en_ligne/data/auth/remembered_user_context_storage.dart';
import 'package:amap_en_ligne/domain/auth/remembered_user_context.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferencesRememberedUserContextStore> _newStore() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return SharedPreferencesRememberedUserContextStore(prefs: prefs);
}

void main() {
  test(
    'write then read returns the remembered context for the same server',
    () async {
      final store = await _newStore();
      await store.write(
        const RememberedUserContext(
          email: 'alice@example.com',
          serverId: 'server-a',
          rememberMe: true,
        ),
      );

      final restored = await store.read(serverId: 'server-a');

      expect(restored?.email, 'alice@example.com');
      expect(restored?.rememberMe, isTrue);
    },
  );

  test(
    'read returns null when the stored context belongs to another server',
    () async {
      final store = await _newStore();
      await store.write(
        const RememberedUserContext(
          email: 'alice@example.com',
          serverId: 'server-a',
          rememberMe: false,
        ),
      );

      expect(await store.read(serverId: 'server-b'), isNull);
    },
  );

  test('clear removes the remembered context', () async {
    final store = await _newStore();
    await store.write(
      const RememberedUserContext(
        email: 'alice@example.com',
        serverId: 'server-a',
        rememberMe: true,
      ),
    );

    await store.clear();

    expect(await store.read(serverId: 'server-a'), isNull);
  });
}
