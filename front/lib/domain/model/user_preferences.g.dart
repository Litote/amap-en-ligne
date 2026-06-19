// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    _UserPreferences(
      emailNotificationsEnabled:
          json['email_notifications_enabled'] as bool? ?? true,
      pushNotificationsEnabled:
          json['push_notifications_enabled'] as bool? ?? true,
      lastUpdatedInstant: json['last_updated_instant'] as String,
    );

Map<String, dynamic> _$UserPreferencesToJson(_UserPreferences instance) =>
    <String, dynamic>{
      'email_notifications_enabled': instance.emailNotificationsEnabled,
      'push_notifications_enabled': instance.pushNotificationsEnabled,
      'last_updated_instant': instance.lastUpdatedInstant,
    };
