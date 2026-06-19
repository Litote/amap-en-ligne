import 'package:amap_en_ligne/data/server/server_config_storage.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _gotruePreset = GoTrueServerConfig(
  id: 'preset-a',
  name: 'Preset A',
  backendUrl: 'http://a',
  gotrueUrl: 'http://a-auth',
);

const _cognitoPreset = CognitoServerConfig(
  id: 'preset-b',
  name: 'Preset B',
  backendUrl: 'http://b',
  userPoolId: 'pool',
  clientId: 'client',
  region: 'eu-west-1',
);

const _presets = [_gotruePreset, _cognitoPreset];

Future<ServerConfigStorage> _newStorage() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ServerConfigStorage(prefs: prefs, presets: _presets);
}

void main() {
  test('read returns null when nothing is persisted', () async {
    final storage = await _newStorage();
    expect(storage.read(), isNull);
  });

  test('write then read returns the same preset by id', () async {
    final storage = await _newStorage();
    await storage.write(_cognitoPreset);
    final restored = storage.read();
    expect(restored, isA<CognitoServerConfig>());
    expect(restored?.toJson(), _cognitoPreset.toJson());
  });

  test(
    'read falls back to the legacy preset id when no serialized config exists',
    () async {
      SharedPreferences.setMockInitialValues({
        'server.selected.id.v1': 'preset-a',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = ServerConfigStorage(prefs: prefs, presets: _presets);
      expect(storage.read()?.toJson(), _gotruePreset.toJson());
    },
  );

  test(
    'read returns null when persisted legacy id is no longer in the preset list',
    () async {
      SharedPreferences.setMockInitialValues({
        'server.selected.id.v1': 'removed-preset',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = ServerConfigStorage(prefs: prefs, presets: _presets);
      expect(storage.read(), isNull);
    },
  );

  test('clear removes the persisted selection', () async {
    final storage = await _newStorage();
    await storage.write(_gotruePreset);
    await storage.clear();
    expect(storage.read(), isNull);
  });
}
