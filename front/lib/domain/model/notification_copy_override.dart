import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_copy_override.freezed.dart';
part 'notification_copy_override.g.dart';

/// Admin-authored override of the title/body used for a given notification
/// category within an organization (mirrors back's `NotificationCopyOverride`).
///
/// Either field may be null/blank, in which case the hardcoded default copy is
/// used for that part. Stored on `Organization.notificationOverrides`.
@freezed
abstract class NotificationCopyOverride with _$NotificationCopyOverride {
  const factory NotificationCopyOverride({String? title, String? body}) =
      _NotificationCopyOverride;

  factory NotificationCopyOverride.fromJson(Map<String, Object?> json) =>
      _$NotificationCopyOverrideFromJson(json);
}
