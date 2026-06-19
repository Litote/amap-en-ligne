// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'producer_creation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProducerCreationRequest _$ProducerCreationRequestFromJson(
  Map<String, dynamic> json,
) => _ProducerCreationRequest(
  producerName: json['producer_name'] as String,
  adminFirstName: json['admin_first_name'] as String,
  adminLastName: json['admin_last_name'] as String,
  adminEmail: json['admin_email'] as String,
  submitterComment: json['submitter_comment'] as String?,
);

Map<String, dynamic> _$ProducerCreationRequestToJson(
  _ProducerCreationRequest instance,
) => <String, dynamic>{
  'producer_name': instance.producerName,
  'admin_first_name': instance.adminFirstName,
  'admin_last_name': instance.adminLastName,
  'admin_email': instance.adminEmail,
  'submitter_comment': ?instance.submitterComment,
};
