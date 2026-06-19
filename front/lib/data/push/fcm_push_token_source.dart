import 'package:amap_en_ligne/data/push/push_token_source.dart';
import 'package:amap_en_ligne/domain/model/device_token.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// FCM-backed [PushTokenSource] (ADR-005).
///
/// Degrades gracefully: any failure to obtain a token — Firebase not initialised,
/// placeholder config, permission denied, unsupported platform (desktop/web
/// without config) — is swallowed and surfaces as `null` / an empty refresh
/// stream, so the rest of the app is unaffected.
class FcmPushTokenSource implements PushTokenSource {
  const FcmPushTokenSource();

  @override
  DevicePlatform get platform {
    if (kIsWeb) return DevicePlatform.web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => DevicePlatform.ios,
      _ => DevicePlatform.android,
    };
  }

  @override
  Future<String?> currentToken() async {
    // Web push is not functional without a real Firebase project configured via
    // `flutterfire configure`. The current firebase_options.dart ships placeholder
    // values; calling getToken() would reach firebaseinstallations.googleapis.com
    // with a fake project id and receive a 400. Skip the whole flow on web until
    // a real project is wired up.
    if (kIsWeb) return null;

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
      return await messaging.getToken();
    } catch (e, s) {
      // Unexpected Firebase error on native — report so we know if the real
      // project config ever breaks. (Placeholder failures on web are guarded
      // above by the kIsWeb early return and never reach this path.)
      await Sentry.captureException(e, stackTrace: s);
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh {
    try {
      return FirebaseMessaging.instance.onTokenRefresh;
    } catch (_) {
      return const Stream<String>.empty();
    }
  }
}
