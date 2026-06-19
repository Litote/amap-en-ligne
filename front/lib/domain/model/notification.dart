import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

/// A user-facing notification on the recipient's private sync feed (ADR-005).
///
/// Mirrors `Notification` in
/// `back/persistence/model/src/main/kotlin/Notification.kt`. Server-authoritative:
/// the client only ever flips [readAt] (mark read) or deletes the row (archive).
/// [createdAt] / [readAt] are ISO-8601 instants on the wire.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    @JsonKey(name: 'notification_id') required String notificationId,
    @JsonKey(name: 'recipient_scope') required String recipientScope,
    required NotificationType type,
    required NotificationCategory category,
    required String title,
    required String body,
    @JsonKey(name: 'deep_link') String? deepLink,
    @JsonKey(name: 'related_entity_id') String? relatedEntityId,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'read_at') String? readAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, Object?> json) =>
      _$AppNotificationFromJson(json);
}

/// Severity / intent. Wire values uppercase, matching the back enum.
enum NotificationType {
  @JsonValue('ALERT')
  alert,
  @JsonValue('REMINDER')
  reminder,
  @JsonValue('INFO')
  info,
  @JsonValue('URGENT')
  urgent,
}

/// Business origin of the notification. Wire values uppercase, matching the back enum.
enum NotificationCategory {
  @JsonValue('GENERIC')
  generic,
  @JsonValue('BASKET_EXCHANGE_REQUEST_RECEIVED')
  basketExchangeRequestReceived,
  @JsonValue('BASKET_EXCHANGE_ACCEPTED')
  basketExchangeAccepted,
  @JsonValue('BASKET_EXCHANGE_REJECTED')
  basketExchangeRejected,
  @JsonValue('MEMBER_JOIN_REQUEST_SUBMITTED')
  memberJoinRequestSubmitted,
  @JsonValue('DELIVERY_REMINDER')
  deliveryReminder,
  @JsonValue('ORGANIZATION_REQUEST_SUBMITTED')
  organizationRequestSubmitted,
  @JsonValue('PRODUCER_REQUEST_SUBMITTED')
  producerRequestSubmitted,
  @JsonValue('SLOT_CANCELLED')
  slotCancelled,
  @JsonValue('SLOT_RESCHEDULED')
  slotRescheduled,
}
