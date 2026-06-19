import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_token.freezed.dart';
part 'device_token.g.dart';

/// A push-capable device registered for the current user on their private sync
/// feed (ADR-005).
///
/// Mirrors `DeviceToken` in `back/persistence/model/src/main/kotlin/DeviceToken.kt`.
/// Client-authored: the app upserts one when it obtains/refreshes a push registration
/// token and deletes it on logout. [createdAt] / [lastSeenAt] are ISO-8601 instants
/// on the wire.
@freezed
abstract class DeviceToken with _$DeviceToken {
  const factory DeviceToken({
    @JsonKey(name: 'device_token_id') required String deviceTokenId,
    @JsonKey(name: 'recipient_scope') required String recipientScope,
    required DevicePlatform platform,
    required String token,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'last_seen_at') required String lastSeenAt,
  }) = _DeviceToken;

  factory DeviceToken.fromJson(Map<String, Object?> json) =>
      _$DeviceTokenFromJson(json);
}

/// Platform a [DeviceToken] was issued for. Wire values uppercase, matching the back enum.
enum DevicePlatform {
  @JsonValue('ANDROID')
  android,
  @JsonValue('IOS')
  ios,
  @JsonValue('WEB')
  web,
}
