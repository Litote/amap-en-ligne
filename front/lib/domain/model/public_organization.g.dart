// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_organization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PublicOrganization _$PublicOrganizationFromJson(Map<String, dynamic> json) =>
    _PublicOrganization(
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      activeStatus: json['active_status'] as bool? ?? true,
    );

Map<String, dynamic> _$PublicOrganizationToJson(_PublicOrganization instance) =>
    <String, dynamic>{
      'organization_id': instance.organizationId,
      'name': instance.name,
      'active_status': instance.activeStatus,
    };
