import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_preferences.freezed.dart';
part 'user_preferences.g.dart';

/// Notification channel preferences for a user across all organizations.
///
/// Mirrors `UserPreferences` in `back/persistence/model/src/main/kotlin/UserCommon.kt`.
/// All boolean fields are non-null with the same defaults as the back.
@freezed
abstract class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    @JsonKey(name: 'email_notifications_enabled')
    @Default(true)
    bool emailNotificationsEnabled,
    @JsonKey(name: 'push_notifications_enabled')
    @Default(true)
    bool pushNotificationsEnabled,
    @JsonKey(name: 'last_updated_instant') required String lastUpdatedInstant,
  }) = _UserPreferences;

  factory UserPreferences.fromJson(Map<String, Object?> json) =>
      _$UserPreferencesFromJson(json);
}
