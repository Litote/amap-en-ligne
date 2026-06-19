import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/presentation/server/server_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _presets = [
  GoTrueServerConfig(
    id: 'preset-a',
    name: 'Preset A',
    backendUrl: 'http://a',
    gotrueUrl: 'http://a-auth',
  ),
  CognitoServerConfig(
    id: 'preset-b',
    name: 'Preset B',
    backendUrl: 'http://b',
    userPoolId: 'pool',
    clientId: 'client',
    region: 'eu-west-1',
  ),
];

void main() {
  testWidgets('renders one tile per preset and reports the tapped config', (
    tester,
  ) async {
    ServerConfig? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: ServerSelectionScreen(
          presets: _presets,
          onSelected: (c) => selected = c,
        ),
      ),
    );

    expect(find.text('Preset A'), findsOneWidget);
    expect(find.text('Preset B'), findsOneWidget);

    await tester.tap(find.byKey(const Key('server_preset_preset-b')));
    expect(selected?.id, 'preset-b');
  });
}
