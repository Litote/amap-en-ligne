// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceToken _$DeviceTokenFromJson(Map<String, dynamic> json) => _DeviceToken(
  deviceTokenId: json['device_token_id'] as String,
  recipientScope: json['recipient_scope'] as String,
  platform: $enumDecode(_$DevicePlatformEnumMap, json['platform']),
  token: json['token'] as String,
  createdAt: json['created_at'] as String,
  lastSeenAt: json['last_seen_at'] as String,
);

Map<String, dynamic> _$DeviceTokenToJson(_DeviceToken instance) =>
    <String, dynamic>{
      'device_token_id': instance.deviceTokenId,
      'recipient_scope': instance.recipientScope,
      'platform': _$DevicePlatformEnumMap[instance.platform]!,
      'token': instance.token,
      'created_at': instance.createdAt,
      'last_seen_at': instance.lastSeenAt,
    };

const _$DevicePlatformEnumMap = {
  DevicePlatform.android: 'ANDROID',
  DevicePlatform.ios: 'IOS',
  DevicePlatform.web: 'WEB',
};
