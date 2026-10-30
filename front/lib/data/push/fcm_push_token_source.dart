import 'dart:async';
import 'package:amap_en_ligne/data/push/push_token_source.dart';
import 'package:amap_en_ligne/domain/model/device_token.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// FCM-backed [PushTokenSource] (ADR-005).
///
/// The push target is the app's **Firebase Installation ID (FID)**, not the
/// deprecated FCM registration token: the app runs in FCM's FID mode (Android
/// manifest `firebase_messaging_installation_id_enabled`, iOS Info.plist
/// `FirebaseMessagingInstallationIdEnabled`), registers itself with FCM through
/// `register()`, then reads its FID — stable for the installation — with
/// `FirebaseInstallations.getId()`. The back sends to it as an FCM `fid`.
///
/// Degrades gracefully: any failure to obtain an FID — Firebase not initialised,
/// placeholder config, permission denied, unsupported platform (desktop/web
/// without config) — is swallowed and surfaces as `null` / an empty refresh
/// stream, so the rest of the app is unaffected.
class FcmPushTokenSource implements PushTokenSource {
  /// [messaging] / [installations] default to the Firebase singletons; tests
  /// inject fakes.
  const FcmPushTokenSource({
    FirebaseMessaging Function()? messaging,
    FirebaseInstallations Function()? installations,
  }) : _messaging = messaging,
       _installations = installations;

  final FirebaseMessaging Function()? _messaging;
  final FirebaseInstallations Function()? _installations;

  FirebaseMessaging get _messagingInstance =>
      _messaging?.call() ?? FirebaseMessaging.instance;

  FirebaseInstallations get _installationsInstance =>
      _installations?.call() ?? FirebaseInstallations.instance;

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
    // values; registering would reach firebaseinstallations.googleapis.com with a
    // fake project id and receive a 400. Skip the whole flow on web until a real
    // project is wired up.
    if (kIsWeb) return null;

    try {
      final messaging = _messagingInstance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
      // Reading the FID alone does not make it a valid FCM target: register
      // first (idempotent), then read the installation's FID.
      await messaging.register();
      return await _installationsInstance.getId();
    } on Exception catch (e, s) {
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
      // Fires with the FID each time FCM (re-)registers this installation.
      return _messagingInstance.onRegistered;
    } on Exception catch (e) {
      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            category: 'fallback',
            level: SentryLevel.warning,
            message: 'onRegistered unavailable: $e',
          ),
        ),
      );
      return const Stream<String>.empty();
    }
  }
}
