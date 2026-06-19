import 'package:amap_en_ligne/domain/model/device_token.dart';

/// Platform boundary for obtaining push registration tokens (ADR-005).
///
/// Implemented by a concrete FCM-backed source (firebase_messaging) once the
/// Firebase project config is wired. Kept as an interface so the registration
/// orchestration ([PushRegistrationService]) and its tests do not depend on the
/// FCM SDK.
abstract interface class PushTokenSource {
  /// Platform this device runs on, used to shape the `DeviceToken`.
  DevicePlatform get platform;

  /// The current push registration token, or null when unavailable
  /// (permission denied, no Play Services, web without config, …).
  Future<String?> currentToken();

  /// Emits a fresh token whenever the platform rotates it.
  Stream<String> get onTokenRefresh;
}
