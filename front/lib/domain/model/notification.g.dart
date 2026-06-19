// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    _AppNotification(
      notificationId: json['notification_id'] as String,
      recipientScope: json['recipient_scope'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      category: $enumDecode(_$NotificationCategoryEnumMap, json['category']),
      title: json['title'] as String,
      body: json['body'] as String,
      deepLink: json['deep_link'] as String?,
      relatedEntityId: json['related_entity_id'] as String?,
      createdAt: json['created_at'] as String,
      readAt: json['read_at'] as String?,
    );

Map<String, dynamic> _$AppNotificationToJson(_AppNotification instance) =>
    <String, dynamic>{
      'notification_id': instance.notificationId,
      'recipient_scope': instance.recipientScope,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'category': _$NotificationCategoryEnumMap[instance.category]!,
      'title': instance.title,
      'body': instance.body,
      'deep_link': ?instance.deepLink,
      'related_entity_id': ?instance.relatedEntityId,
      'created_at': instance.createdAt,
      'read_at': ?instance.readAt,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.alert: 'ALERT',
  NotificationType.reminder: 'REMINDER',
  NotificationType.info: 'INFO',
  NotificationType.urgent: 'URGENT',
};

const _$NotificationCategoryEnumMap = {
  NotificationCategory.generic: 'GENERIC',
  NotificationCategory.basketExchangeRequestReceived:
      'BASKET_EXCHANGE_REQUEST_RECEIVED',
  NotificationCategory.basketExchangeAccepted: 'BASKET_EXCHANGE_ACCEPTED',
  NotificationCategory.basketExchangeRejected: 'BASKET_EXCHANGE_REJECTED',
  NotificationCategory.memberJoinRequestSubmitted:
      'MEMBER_JOIN_REQUEST_SUBMITTED',
  NotificationCategory.deliveryReminder: 'DELIVERY_REMINDER',
  NotificationCategory.organizationRequestSubmitted:
      'ORGANIZATION_REQUEST_SUBMITTED',
  NotificationCategory.producerRequestSubmitted: 'PRODUCER_REQUEST_SUBMITTED',
  NotificationCategory.slotCancelled: 'SLOT_CANCELLED',
  NotificationCategory.slotRescheduled: 'SLOT_RESCHEDULED',
};
