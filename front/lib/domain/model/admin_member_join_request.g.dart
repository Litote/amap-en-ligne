// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_member_join_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdminMemberJoinRequest _$AdminMemberJoinRequestFromJson(
  Map<String, dynamic> json,
) => _AdminMemberJoinRequest(
  requestId: json['request_id'] as String,
  organizationId: json['organization_id'] as String,
  email: json['email'] as String,
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
  status: $enumDecode(_$MemberJoinRequestStatusEnumMap, json['status']),
  submittedAt: json['submitted_at'] as String,
  reviewedAt: json['reviewed_at'] as String?,
  reviewComment: json['review_comment'] as String?,
);

Map<String, dynamic> _$AdminMemberJoinRequestToJson(
  _AdminMemberJoinRequest instance,
) => <String, dynamic>{
  'request_id': instance.requestId,
  'organization_id': instance.organizationId,
  'email': instance.email,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'status': _$MemberJoinRequestStatusEnumMap[instance.status]!,
  'submitted_at': instance.submittedAt,
  'reviewed_at': ?instance.reviewedAt,
  'review_comment': ?instance.reviewComment,
};

const _$MemberJoinRequestStatusEnumMap = {
  MemberJoinRequestStatus.pending: 'PENDING',
  MemberJoinRequestStatus.approved: 'APPROVED',
  MemberJoinRequestStatus.rejected: 'REJECTED',
};
