// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberRegistration _$MemberRegistrationFromJson(Map<String, dynamic> json) =>
    _MemberRegistration(
      memberId: json['member_id'] as String,
      displayName: json['display_name'] as String,
      memberEmail: json['member_email'] as String,
      registrationInstant: json['registration_instant'] as String,
      status: $enumDecode(_$RegistrationStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$MemberRegistrationToJson(_MemberRegistration instance) =>
    <String, dynamic>{
      'member_id': instance.memberId,
      'display_name': instance.displayName,
      'member_email': instance.memberEmail,
      'registration_instant': instance.registrationInstant,
      'status': _$RegistrationStatusEnumMap[instance.status]!,
    };

const _$RegistrationStatusEnumMap = {
  RegistrationStatus.registered: 'REGISTERED',
  RegistrationStatus.confirmed: 'CONFIRMED',
  RegistrationStatus.cancelled: 'CANCELLED',
  RegistrationStatus.completed: 'COMPLETED',
};

_MemberSlot _$MemberSlotFromJson(Map<String, dynamic> json) => _MemberSlot(
  slotId: json['slot_id'] as String?,
  startTime: json['start_time'] as String,
  endTime: json['end_time'] as String,
  activityType: $enumDecode(_$ActivityTypeEnumMap, json['activity_type']),
  requiredVolunteers: (json['required_volunteers'] as num).toInt(),
  currentRegistrations: (json['current_registrations'] as num).toInt(),
  status: $enumDecode(_$SlotStatusEnumMap, json['status']),
  slotKind:
      $enumDecodeNullable(_$SlotKindEnumMap, json['slot_kind']) ??
      SlotKind.standard,
  registrations:
      (json['registrations'] as List<dynamic>?)
          ?.map((e) => MemberRegistration.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$MemberSlotToJson(_MemberSlot instance) =>
    <String, dynamic>{
      'slot_id': ?instance.slotId,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'activity_type': _$ActivityTypeEnumMap[instance.activityType]!,
      'required_volunteers': instance.requiredVolunteers,
      'current_registrations': instance.currentRegistrations,
      'status': _$SlotStatusEnumMap[instance.status]!,
      'slot_kind': _$SlotKindEnumMap[instance.slotKind]!,
      'registrations': instance.registrations,
    };

const _$ActivityTypeEnumMap = {
  ActivityType.preparation: 'PREPARATION',
  ActivityType.reception: 'RECEPTION',
  ActivityType.distribution: 'DISTRIBUTION',
};

const _$SlotStatusEnumMap = {
  SlotStatus.open: 'OPEN',
  SlotStatus.critical: 'CRITICAL',
  SlotStatus.full: 'FULL',
  SlotStatus.closed: 'CLOSED',
  SlotStatus.cancelled: 'CANCELLED',
};

const _$SlotKindEnumMap = {
  SlotKind.standard: 'STANDARD',
  SlotKind.early: 'EARLY',
};

_DeliveryContract _$DeliveryContractFromJson(Map<String, dynamic> json) =>
    _DeliveryContract(
      contractId: json['contract_id'] as String,
      coordinators:
          (json['coordinators'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      basketQuantity: (json['basket_quantity'] as num).toInt(),
      deliveryDescription: json['delivery_description'] as String,
      preparationNotes: json['preparation_notes'] as String?,
      status: $enumDecode(_$DeliveryContractStatusEnumMap, json['status']),
      slots:
          (json['slots'] as List<dynamic>?)
              ?.map((e) => MemberSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DeliveryContractToJson(_DeliveryContract instance) =>
    <String, dynamic>{
      'contract_id': instance.contractId,
      'coordinators': instance.coordinators,
      'basket_quantity': instance.basketQuantity,
      'delivery_description': instance.deliveryDescription,
      'preparation_notes': ?instance.preparationNotes,
      'status': _$DeliveryContractStatusEnumMap[instance.status]!,
      'slots': instance.slots,
    };

const _$DeliveryContractStatusEnumMap = {
  DeliveryContractStatus.pending: 'PENDING',
  DeliveryContractStatus.prepared: 'PREPARED',
  DeliveryContractStatus.distributed: 'DISTRIBUTED',
};

_DeliveryItem _$DeliveryItemFromJson(Map<String, dynamic> json) =>
    _DeliveryItem(
      itemTypeId: json['item_type_id'] as String,
      name: json['name'] as String? ?? '',
      weight: json['weight'] as String?,
    );

Map<String, dynamic> _$DeliveryItemToJson(_DeliveryItem instance) =>
    <String, dynamic>{
      'item_type_id': instance.itemTypeId,
      'name': instance.name,
      'weight': ?instance.weight,
    };

_BasketDeliveryDescription _$BasketDeliveryDescriptionFromJson(
  Map<String, dynamic> json,
) => _BasketDeliveryDescription(
  productTypeId: json['product_type_id'] as String,
  basketSizeName: json['basket_size_name'] as String,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => DeliveryItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DeliveryItem>[],
);

Map<String, dynamic> _$BasketDeliveryDescriptionToJson(
  _BasketDeliveryDescription instance,
) => <String, dynamic>{
  'product_type_id': instance.productTypeId,
  'basket_size_name': instance.basketSizeName,
  'items': instance.items,
};

_Delivery _$DeliveryFromJson(Map<String, dynamic> json) => _Delivery(
  deliveryId: json['delivery_id'] as String,
  organizationId: json['organization_id'] as String,
  scheduledDate: json['scheduled_date'] as String,
  status: $enumDecode(_$DeliveryStatusEnumMap, json['status']),
  minVolunteersRequired: (json['min_volunteers_required'] as num).toInt(),
  deliveryTemplateId: json['delivery_template_id'] as String?,
  standardEndTime: json['standard_end_time'] as String?,
  volunteerArrivalTime: json['volunteer_arrival_time'] as String?,
  earlySlot: json['early_slot'] == null
      ? null
      : EarlySlot.fromJson(json['early_slot'] as Map<String, dynamic>),
  contracts:
      (json['contracts'] as List<dynamic>?)
          ?.map((e) => DeliveryContract.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  basketDescriptions:
      (json['basket_descriptions'] as List<dynamic>?)
          ?.map(
            (e) =>
                BasketDeliveryDescription.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <BasketDeliveryDescription>[],
);

Map<String, dynamic> _$DeliveryToJson(_Delivery instance) => <String, dynamic>{
  'delivery_id': instance.deliveryId,
  'organization_id': instance.organizationId,
  'scheduled_date': instance.scheduledDate,
  'status': _$DeliveryStatusEnumMap[instance.status]!,
  'min_volunteers_required': instance.minVolunteersRequired,
  'delivery_template_id': ?instance.deliveryTemplateId,
  'standard_end_time': ?instance.standardEndTime,
  'volunteer_arrival_time': ?instance.volunteerArrivalTime,
  'early_slot': ?instance.earlySlot,
  'contracts': instance.contracts,
  'basket_descriptions': instance.basketDescriptions,
};

const _$DeliveryStatusEnumMap = {
  DeliveryStatus.planned: 'PLANNED',
  DeliveryStatus.confirmed: 'CONFIRMED',
  DeliveryStatus.inProgress: 'IN_PROGRESS',
  DeliveryStatus.completed: 'COMPLETED',
  DeliveryStatus.cancelled: 'CANCELLED',
};

_OrganizationProducer _$OrganizationProducerFromJson(
  Map<String, dynamic> json,
) => _OrganizationProducer(
  producerAccountId: json['producer_account_id'] as String,
  associationInstant: json['association_instant'] as String,
  status: $enumDecode(_$OrganizationProducerStatusEnumMap, json['status']),
);

Map<String, dynamic> _$OrganizationProducerToJson(
  _OrganizationProducer instance,
) => <String, dynamic>{
  'producer_account_id': instance.producerAccountId,
  'association_instant': instance.associationInstant,
  'status': _$OrganizationProducerStatusEnumMap[instance.status]!,
};

const _$OrganizationProducerStatusEnumMap = {
  OrganizationProducerStatus.active: 'ACTIVE',
  OrganizationProducerStatus.suspended: 'SUSPENDED',
  OrganizationProducerStatus.terminated: 'TERMINATED',
};

_OrgProduct _$OrgProductFromJson(Map<String, dynamic> json) => _OrgProduct(
  name: json['name'] as String,
  productTypeId: json['product_type_id'] as String,
  producerAccountId: json['producer_account_id'] as String,
  supportedBasketSizes:
      (json['supported_basket_sizes'] as List<dynamic>?)
          ?.map((e) => BasketSize.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  description: json['description'] as String?,
);

Map<String, dynamic> _$OrgProductToJson(_OrgProduct instance) =>
    <String, dynamic>{
      'name': instance.name,
      'product_type_id': instance.productTypeId,
      'producer_account_id': instance.producerAccountId,
      'supported_basket_sizes': instance.supportedBasketSizes,
      'description': ?instance.description,
    };

_Organization _$OrganizationFromJson(
  Map<String, dynamic> json,
) => _Organization(
  organizationId: json['organization_id'] as String,
  name: json['name'] as String,
  contactEmail: json['contact_email'] as String,
  activeStatus: json['active_status'] as bool? ?? true,
  timezone: json['timezone'] as String?,
  defaultLanguage: json['default_language'] as String?,
  defaultDeliveryTemplateId: json['default_delivery_template_id'] as String?,
  website: json['website'] as String?,
  createdInstant: json['created_instant'] as String?,
  lastUpdatedInstant: json['last_updated_instant'] as String?,
  producers:
      (json['producers'] as List<dynamic>?)
          ?.map((e) => OrganizationProducer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  products:
      (json['products'] as List<dynamic>?)
          ?.map((e) => OrgProduct.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  deliveries:
      (json['deliveries'] as List<dynamic>?)
          ?.map((e) => Delivery.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  itemTypes:
      (json['item_types'] as List<dynamic>?)
          ?.map((e) => ItemType.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ItemType>[],
  notificationOverrides:
      (json['notification_overrides'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          $enumDecode(_$NotificationCategoryEnumMap, k),
          NotificationCopyOverride.fromJson(e as Map<String, dynamic>),
        ),
      ) ??
      const <NotificationCategory, NotificationCopyOverride>{},
);

Map<String, dynamic> _$OrganizationToJson(_Organization instance) =>
    <String, dynamic>{
      'organization_id': instance.organizationId,
      'name': instance.name,
      'contact_email': instance.contactEmail,
      'active_status': instance.activeStatus,
      'timezone': ?instance.timezone,
      'default_language': ?instance.defaultLanguage,
      'default_delivery_template_id': ?instance.defaultDeliveryTemplateId,
      'website': ?instance.website,
      'created_instant': ?instance.createdInstant,
      'last_updated_instant': ?instance.lastUpdatedInstant,
      'producers': instance.producers,
      'products': instance.products,
      'deliveries': instance.deliveries,
      'item_types': instance.itemTypes,
      'notification_overrides': instance.notificationOverrides.map(
        (k, e) => MapEntry(_$NotificationCategoryEnumMap[k]!, e),
      ),
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
