// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Change _$ChangeFromJson(Map<String, dynamic> json) => _Change(
  cursor: json['cursor'] as String?,
  entityType: $enumDecode(_$EntityTypeEnumMap, json['entity_type']),
  entityId: json['entity_id'] as String,
  producerAccountId: json['producer_account_id'] as String?,
  op: $enumDecode(_$ChangeOpEnumMap, json['op']),
  payload: json['payload'] == null
      ? null
      : EntityPayload.fromJson(json['payload'] as Map<String, dynamic>),
  producedAt: (json['produced_at'] as num).toInt(),
);

Map<String, dynamic> _$ChangeToJson(_Change instance) => <String, dynamic>{
  'cursor': ?instance.cursor,
  'entity_type': _$EntityTypeEnumMap[instance.entityType]!,
  'entity_id': instance.entityId,
  'producer_account_id': ?instance.producerAccountId,
  'op': _$ChangeOpEnumMap[instance.op]!,
  'payload': ?instance.payload,
  'produced_at': instance.producedAt,
};

const _$EntityTypeEnumMap = {
  EntityType.productType: 'ProductType',
  EntityType.organization: 'Organization',
  EntityType.producerAccount: 'ProducerAccount',
  EntityType.member: 'Member',
  EntityType.memberJoinRequest: 'MemberJoinRequest',
  EntityType.contract: 'Contract',
  EntityType.deliveryTemplate: 'DeliveryTemplate',
  EntityType.organizationRequest: 'OrganizationRequest',
  EntityType.producerRequest: 'ProducerRequest',
  EntityType.owner: 'Owner',
  EntityType.memberInvitation: 'MemberInvitation',
  EntityType.ownerInvitation: 'OwnerInvitation',
  EntityType.basketExchange: 'BasketExchange',
  EntityType.notification: 'Notification',
  EntityType.deviceToken: 'DeviceToken',
  EntityType.attendanceEmailRequest: 'AttendanceEmailRequest',
  EntityType.errorReport: 'ErrorReport',
};

const _$ChangeOpEnumMap = {
  ChangeOp.upsert: 'UPSERT',
  ChangeOp.delete: 'DELETE',
};
