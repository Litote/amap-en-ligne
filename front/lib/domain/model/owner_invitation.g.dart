// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OwnerInvitation _$OwnerInvitationFromJson(Map<String, dynamic> json) =>
    _OwnerInvitation(
      invitationId: json['invitation_id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      status: $enumDecode(_$InvitationStatusEnumMap, json['status']),
      submittedAt: json['submitted_at'] as String,
      resendRequestedAt: json['resend_requested_at'] as String?,
      activatedAt: json['activated_at'] as String?,
    );

Map<String, dynamic> _$OwnerInvitationToJson(_OwnerInvitation instance) =>
    <String, dynamic>{
      'invitation_id': instance.invitationId,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'status': _$InvitationStatusEnumMap[instance.status]!,
      'submitted_at': instance.submittedAt,
      'resend_requested_at': ?instance.resendRequestedAt,
      'activated_at': ?instance.activatedAt,
    };

const _$InvitationStatusEnumMap = {
  InvitationStatus.pendingActivation: 'PENDING_ACTIVATION',
  InvitationStatus.activated: 'ACTIVATED',
  InvitationStatus.cancelled: 'CANCELLED',
};
