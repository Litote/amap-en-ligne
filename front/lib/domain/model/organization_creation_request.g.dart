// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_creation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrganizationCreationRequest _$OrganizationCreationRequestFromJson(
  Map<String, dynamic> json,
) => _OrganizationCreationRequest(
  organizationName: json['organization_name'] as String,
  timezone: json['timezone'] as String,
  defaultLanguage: json['default_language'] as String,
  adminFirstName: json['admin_first_name'] as String,
  adminLastName: json['admin_last_name'] as String,
  adminEmail: json['admin_email'] as String,
  organizationType: $enumDecode(
    _$OrganizationTypeEnumMap,
    json['organization_type'],
  ),
  submitterComment: json['submitter_comment'] as String?,
);

Map<String, dynamic> _$OrganizationCreationRequestToJson(
  _OrganizationCreationRequest instance,
) => <String, dynamic>{
  'organization_name': instance.organizationName,
  'timezone': instance.timezone,
  'default_language': instance.defaultLanguage,
  'admin_first_name': instance.adminFirstName,
  'admin_last_name': instance.adminLastName,
  'admin_email': instance.adminEmail,
  'organization_type': _$OrganizationTypeEnumMap[instance.organizationType]!,
  'submitter_comment': ?instance.submitterComment,
};

const _$OrganizationTypeEnumMap = {
  OrganizationType.amap: 'AMAP',
  OrganizationType.producer: 'PRODUCER',
};
