import 'package:amap_en_ligne/data/server/server_config_storage.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _backUrl = String.fromEnvironment('BACK_URL');
const _gotrueUrl = String.fromEnvironment('GOTRUE_URL');
const _testEmail = String.fromEnvironment('TEST_EMAIL');
const _testPassword = String.fromEnvironment('TEST_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'sign in with valid credentials navigates to product types screen',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await ServerConfigStorage(prefs: prefs).write(
        GoTrueServerConfig(
          id: 'integration-test',
          name: 'Integration Test Backend',
          backendUrl: _backUrl,
          gotrueUrl: _gotrueUrl,
        ),
      );

      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('SE CONNECTER'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('login_email')), _testEmail);
      await tester.enterText(
        find.byKey(const Key('login_password')),
        _testPassword,
      );
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 30),
      );

      expect(find.text('Types de produits'), findsOneWidget);
    },
  );
}
