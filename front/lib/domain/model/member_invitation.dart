import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'member_invitation.freezed.dart';
part 'member_invitation.g.dart';

@freezed
abstract class MemberInvitation with _$MemberInvitation {
  const factory MemberInvitation({
    @JsonKey(name: 'invitation_id') required String invitationId,
    @JsonKey(name: 'organization_id') required String organizationId,
    required String email,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    required Set<Role> roles,
    required InvitationStatus status,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'expires_at') required String expiresAt,
    @JsonKey(name: 'resend_requested_at') String? resendRequestedAt,
    @JsonKey(name: 'activated_at') String? activatedAt,
    @JsonKey(name: 'custom_email_subject') String? customEmailSubject,
    @JsonKey(name: 'custom_email_body') String? customEmailBody,
  }) = _MemberInvitation;

  factory MemberInvitation.fromJson(Map<String, Object?> json) =>
      _$MemberInvitationFromJson(json);
}
