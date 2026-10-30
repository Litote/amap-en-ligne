import 'package:amap_en_ligne/data/push/push_registration_service.dart'
    show PushRegistrationService;
import 'package:amap_en_ligne/domain/model/device_token.dart';

/// Platform boundary for obtaining the device's push target (ADR-005): with
/// FCM, the Firebase Installation ID (FID) of the app installation.
///
/// Implemented by a concrete FCM-backed source (firebase_messaging) once the
/// Firebase project config is wired. Kept as an interface so the registration
/// orchestration ([PushRegistrationService]) and its tests do not depend on the
/// FCM SDK.
abstract interface class PushTokenSource {
  /// Platform this device runs on, used to shape the `DeviceToken`.
  DevicePlatform get platform;

  /// The current push target (FCM: the FID), or null when unavailable
  /// (permission denied, no Play Services, web without config, …).
  Future<String?> currentToken();

  /// Emits the push target each time the platform (re-)registers it.
  Stream<String> get onTokenRefresh;
}
