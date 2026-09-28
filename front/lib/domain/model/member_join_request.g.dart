// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_join_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberJoinRequest _$MemberJoinRequestFromJson(Map<String, dynamic> json) =>
    _MemberJoinRequest(
      organizationId: json['organization_id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
    );

Map<String, dynamic> _$MemberJoinRequestToJson(_MemberJoinRequest instance) =>
    <String, dynamic>{
      'organization_id': instance.organizationId,
      'email': instance.email,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
    };

_MemberJoinRequestResponse _$MemberJoinRequestResponseFromJson(
  Map<String, dynamic> json,
) => _MemberJoinRequestResponse(
  requestId: json['request_id'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$MemberJoinRequestResponseToJson(
  _MemberJoinRequestResponse instance,
) => <String, dynamic>{
  'request_id': instance.requestId,
  'status': instance.status,
};
