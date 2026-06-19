import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'owner_invitation.freezed.dart';
part 'owner_invitation.g.dart';

@freezed
abstract class OwnerInvitation with _$OwnerInvitation {
  const factory OwnerInvitation({
    @JsonKey(name: 'invitation_id') required String invitationId,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    required String email,
    required InvitationStatus status,
    @JsonKey(name: 'submitted_at') required String submittedAt,
    @JsonKey(name: 'resend_requested_at') String? resendRequestedAt,
    @JsonKey(name: 'activated_at') String? activatedAt,
  }) = _OwnerInvitation;

  factory OwnerInvitation.fromJson(Map<String, Object?> json) =>
      _$OwnerInvitationFromJson(json);
}
