// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EarlySlot _$EarlySlotFromJson(Map<String, dynamic> json) => _EarlySlot(
  arrivalTime: json['arrival_time'] as String,
  explanation: json['explanation'] as String?,
  maxVolunteers: (json['max_volunteers'] as num).toInt(),
);

Map<String, dynamic> _$EarlySlotToJson(_EarlySlot instance) =>
    <String, dynamic>{
      'arrival_time': instance.arrivalTime,
      'explanation': ?instance.explanation,
      'max_volunteers': instance.maxVolunteers,
    };

_DeliveryTemplate _$DeliveryTemplateFromJson(Map<String, dynamic> json) =>
    _DeliveryTemplate(
      deliveryTemplateId: json['delivery_template_id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      standardStartTime: json['standard_start_time'] as String,
      standardEndTime: json['standard_end_time'] as String,
      volunteerArrivalTime: json['volunteer_arrival_time'] as String?,
      desiredVolunteerCount:
          (json['desired_volunteer_count'] as num?)?.toInt() ?? 1,
      earlySlot: json['early_slot'] == null
          ? null
          : EarlySlot.fromJson(json['early_slot'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DeliveryTemplateToJson(_DeliveryTemplate instance) =>
    <String, dynamic>{
      'delivery_template_id': instance.deliveryTemplateId,
      'organization_id': instance.organizationId,
      'name': instance.name,
      'standard_start_time': instance.standardStartTime,
      'standard_end_time': instance.standardEndTime,
      'volunteer_arrival_time': ?instance.volunteerArrivalTime,
      'desired_volunteer_count': instance.desiredVolunteerCount,
      'early_slot': ?instance.earlySlot,
    };
