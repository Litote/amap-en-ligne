// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_request_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrganizationRequestResponse _$OrganizationRequestResponseFromJson(
  Map<String, dynamic> json,
) => _OrganizationRequestResponse(
  requestId: json['request_id'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$OrganizationRequestResponseToJson(
  _OrganizationRequestResponse instance,
) => <String, dynamic>{
  'request_id': instance.requestId,
  'status': instance.status,
};
