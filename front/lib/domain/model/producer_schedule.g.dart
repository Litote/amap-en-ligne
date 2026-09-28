// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'producer_schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProducerSchedule _$ProducerScheduleFromJson(Map<String, dynamic> json) =>
    _ProducerSchedule(
      organizationId: json['organization_id'] as String,
      producerAccountId: json['producer_account_id'] as String,
      organizationName: json['organization_name'] as String,
      deliveries:
          (json['deliveries'] as List<dynamic>?)
              ?.map(
                (e) => ProducerScheduleDelivery.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const <ProducerScheduleDelivery>[],
    );

Map<String, dynamic> _$ProducerScheduleToJson(_ProducerSchedule instance) =>
    <String, dynamic>{
      'organization_id': instance.organizationId,
      'producer_account_id': instance.producerAccountId,
      'organization_name': instance.organizationName,
      'deliveries': instance.deliveries,
    };

_ProducerScheduleDelivery _$ProducerScheduleDeliveryFromJson(
  Map<String, dynamic> json,
) => _ProducerScheduleDelivery(
  deliveryId: json['delivery_id'] as String,
  scheduledDate: json['scheduled_date'] as String,
  status: $enumDecode(_$DeliveryStatusEnumMap, json['status']),
  contracts:
      (json['contracts'] as List<dynamic>?)
          ?.map(
            (e) => ProducerScheduleContract.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ProducerScheduleContract>[],
  basketDescriptions:
      (json['basket_descriptions'] as List<dynamic>?)
          ?.map(
            (e) =>
                BasketDeliveryDescription.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <BasketDeliveryDescription>[],
);

Map<String, dynamic> _$ProducerScheduleDeliveryToJson(
  _ProducerScheduleDelivery instance,
) => <String, dynamic>{
  'delivery_id': instance.deliveryId,
  'scheduled_date': instance.scheduledDate,
  'status': _$DeliveryStatusEnumMap[instance.status]!,
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

_ProducerScheduleContract _$ProducerScheduleContractFromJson(
  Map<String, dynamic> json,
) => _ProducerScheduleContract(
  contractId: json['contract_id'] as String,
  contractName: json['contract_name'] as String,
  basketQuantity: (json['basket_quantity'] as num).toInt(),
  status: $enumDecode(_$DeliveryContractStatusEnumMap, json['status']),
  contractStatus: $enumDecodeNullable(
    _$ContractStatusEnumMap,
    json['contract_status'],
  ),
);

Map<String, dynamic> _$ProducerScheduleContractToJson(
  _ProducerScheduleContract instance,
) => <String, dynamic>{
  'contract_id': instance.contractId,
  'contract_name': instance.contractName,
  'basket_quantity': instance.basketQuantity,
  'status': _$DeliveryContractStatusEnumMap[instance.status]!,
  'contract_status': ?_$ContractStatusEnumMap[instance.contractStatus],
};

const _$DeliveryContractStatusEnumMap = {
  DeliveryContractStatus.pending: 'PENDING',
  DeliveryContractStatus.prepared: 'PREPARED',
  DeliveryContractStatus.distributed: 'DISTRIBUTED',
};

const _$ContractStatusEnumMap = {
  ContractStatus.inPreparation: 'IN_PREPARATION',
  ContractStatus.active: 'ACTIVE',
  ContractStatus.ended: 'ENDED',
};
