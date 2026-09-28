import 'package:freezed_annotation/freezed_annotation.dart';

part 'member_preferences.freezed.dart';
part 'member_preferences.g.dart';

/// Notification and reminder preferences for a member within an organization.
///
/// Mirrors `MemberPreferences` in `back/persistence/model/src/main/kotlin/Member.kt`.
/// All boolean fields are non-null with the same defaults as the back.
@freezed
abstract class MemberPreferences with _$MemberPreferences {
  const factory MemberPreferences({
    @JsonKey(name: 'delivery_reminders_enabled')
    @Default(true)
    bool deliveryRemindersEnabled,
    @JsonKey(name: 'volunteer_alerts_enabled')
    @Default(true)
    bool volunteerAlertsEnabled,
    @JsonKey(name: 'reminder_24h_enabled')
    @Default(true)
    bool reminder24hEnabled,
    @JsonKey(name: 'reminder_2h_enabled') @Default(true) bool reminder2hEnabled,
    @JsonKey(name: 'reminder_30min_enabled')
    @Default(false)
    bool reminder30minEnabled,
    @JsonKey(name: 'urgent_need_alerts_enabled')
    @Default(true)
    bool urgentNeedAlertsEnabled,
    @JsonKey(name: 'incomplete_slot_reminders_enabled')
    @Default(false)
    bool incompleteSlotRemindersEnabled,
    @JsonKey(name: 'planning_changes_alerts_enabled')
    @Default(true)
    bool planningChangesAlertsEnabled,
    @JsonKey(name: 'last_updated_instant') required String lastUpdatedInstant,
  }) = _MemberPreferences;

  factory MemberPreferences.fromJson(Map<String, Object?> json) =>
      _$MemberPreferencesFromJson(json);
}
