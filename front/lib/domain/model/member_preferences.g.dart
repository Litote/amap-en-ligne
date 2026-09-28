// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberPreferences _$MemberPreferencesFromJson(
  Map<String, dynamic> json,
) => _MemberPreferences(
  deliveryRemindersEnabled: json['delivery_reminders_enabled'] as bool? ?? true,
  volunteerAlertsEnabled: json['volunteer_alerts_enabled'] as bool? ?? true,
  urgentNeedAlertsEnabled: json['urgent_need_alerts_enabled'] as bool? ?? true,
  incompleteSlotRemindersEnabled:
      json['incomplete_slot_reminders_enabled'] as bool? ?? false,
  planningChangesAlertsEnabled:
      json['planning_changes_alerts_enabled'] as bool? ?? true,
  lastUpdatedInstant: json['last_updated_instant'] as String,
);

Map<String, dynamic> _$MemberPreferencesToJson(
  _MemberPreferences instance,
) => <String, dynamic>{
  'delivery_reminders_enabled': instance.deliveryRemindersEnabled,
  'volunteer_alerts_enabled': instance.volunteerAlertsEnabled,
  'urgent_need_alerts_enabled': instance.urgentNeedAlertsEnabled,
  'incomplete_slot_reminders_enabled': instance.incompleteSlotRemindersEnabled,
  'planning_changes_alerts_enabled': instance.planningChangesAlertsEnabled,
  'last_updated_instant': instance.lastUpdatedInstant,
};
