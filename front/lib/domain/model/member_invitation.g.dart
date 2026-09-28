// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberInvitation _$MemberInvitationFromJson(Map<String, dynamic> json) =>
    _MemberInvitation(
      invitationId: json['invitation_id'] as String,
      organizationId: json['organization_id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      roles: (json['roles'] as List<dynamic>)
          .map((e) => $enumDecode(_$RoleEnumMap, e))
          .toSet(),
      status: $enumDecode(_$InvitationStatusEnumMap, json['status']),
      createdAt: json['created_at'] as String,
      expiresAt: json['expires_at'] as String,
      resendRequestedAt: json['resend_requested_at'] as String?,
      activatedAt: json['activated_at'] as String?,
      customEmailSubject: json['custom_email_subject'] as String?,
      customEmailBody: json['custom_email_body'] as String?,
    );

Map<String, dynamic> _$MemberInvitationToJson(_MemberInvitation instance) =>
    <String, dynamic>{
      'invitation_id': instance.invitationId,
      'organization_id': instance.organizationId,
      'email': instance.email,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'roles': instance.roles.map((e) => _$RoleEnumMap[e]!).toList(),
      'status': _$InvitationStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt,
      'expires_at': instance.expiresAt,
      'resend_requested_at': ?instance.resendRequestedAt,
      'activated_at': ?instance.activatedAt,
      'custom_email_subject': ?instance.customEmailSubject,
      'custom_email_body': ?instance.customEmailBody,
    };

const _$RoleEnumMap = {
  Role.owner: 'OWNER',
  Role.admin: 'ADMIN',
  Role.producer: 'PRODUCER',
  Role.coordinator: 'COORDINATOR',
  Role.volunteer: 'VOLUNTEER',
};

const _$InvitationStatusEnumMap = {
  InvitationStatus.pendingActivation: 'PENDING_ACTIVATION',
  InvitationStatus.activated: 'ACTIVATED',
  InvitationStatus.cancelled: 'CANCELLED',
};
