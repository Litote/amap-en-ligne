import 'package:amap_en_ligne/data/server/server_config_storage.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/main.dart' as app;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _backUrl = String.fromEnvironment('BACK_URL');
const _gotrueUrl = String.fromEnvironment('GOTRUE_URL');

/// Kotlin-side OTP proxy URL — exposes GET /otp?email=... with CORS headers.
/// The proxy polls MailHog server-side (no CORS restriction) so Flutter does
/// not need to call MailHog directly from Chrome.
const _otpProxyUrl = String.fromEnvironment('OTP_PROXY_URL');

const _testEmail = String.fromEnvironment('TEST_EMAIL');
const _newPassword = String.fromEnvironment('NEW_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('forgot-password OTP flow resets password and allows sign-in', (
    tester,
  ) async {
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

    // Navigate to login then forgot-password.
    await tester.tap(find.text('SE CONNECTER'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();

    // Request a reset OTP for the test email.
    await tester.enterText(find.byKey(const Key('forgot_email')), _testEmail);
    await tester.tap(find.byKey(const Key('forgot_submit')));
    // pumpAndSettle cannot settle while there are open HTTP connections (dio
    // keepalive).  Pump frames at a fixed interval until the confirm form
    // appears instead.
    await _pumpUntil(tester, find.byKey(const Key('forgot_token')));

    // Fetch the OTP from the Kotlin-side proxy.  The proxy polls MailHog
    // server-side (no CORS restriction) and returns the token once the email
    // arrives, with Access-Control-Allow-Origin: * so Chrome accepts it.
    final otp = await tester.runAsync(
      () => _fetchOtpFromProxy(_otpProxyUrl, _testEmail),
    );
    expect(otp, isNotNull, reason: 'Recovery OTP not received from proxy');

    // Enter OTP and new password.
    await tester.enterText(find.byKey(const Key('forgot_token')), otp!);
    await tester.enterText(
      find.byKey(const Key('forgot_new_password')),
      _newPassword,
    );
    await tester.enterText(
      find.byKey(const Key('forgot_confirm_password')),
      _newPassword,
    );
    await tester.tap(find.byKey(const Key('forgot_confirm_submit')));
    // confirmPasswordReset calls signInWithSession internally, so the user is
    // already authenticated when the BlocListener navigates to /login.
    // The router's redirect fires immediately and lands on /product-types.
    await _pumpUntil(tester, find.text('Types de produits'));

    expect(find.text('Types de produits'), findsOneWidget);
  });
}

/// Pumps frames at [interval] until [finder] matches at least one widget or
/// [timeout] expires.  Does NOT require the whole widget tree to be idle, so
/// it works correctly even when background streams or keepalive connections
/// prevent [WidgetTester.pumpAndSettle] from settling.
Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  Duration interval = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Widget not found within ${timeout.inSeconds}s: $finder');
    }
    await tester.pump(interval);
  }
}

/// Calls the Kotlin OTP proxy and waits up to 20 s for it to return the token.
/// The proxy blocks until MailHog delivers the recovery email, then returns
/// the raw token string (or empty on timeout).
Future<String?> _fetchOtpFromProxy(String proxyUrl, String email) async {
  final dio = Dio(
    BaseOptions(
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 5),
    ),
  );
  try {
    final response = await dio.get<String>(
      '$proxyUrl/otp',
      queryParameters: {'email': email},
    );
    final otp = response.data;
    return (otp != null && otp.isNotEmpty) ? otp : null;
  } catch (_) {
    return null;
  }
}
