import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_member_join_request.freezed.dart';
part 'admin_member_join_request.g.dart';

enum MemberJoinRequestStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('REJECTED')
  rejected,
}

@freezed
abstract class AdminMemberJoinRequest with _$AdminMemberJoinRequest {
  const factory AdminMemberJoinRequest({
    @JsonKey(name: 'request_id') required String requestId,
    @JsonKey(name: 'organization_id') required String organizationId,
    required String email,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    required MemberJoinRequestStatus status,
    @JsonKey(name: 'submitted_at') required String submittedAt,
    @JsonKey(name: 'reviewed_at') String? reviewedAt,
    @JsonKey(name: 'review_comment') String? reviewComment,
  }) = _AdminMemberJoinRequest;

  factory AdminMemberJoinRequest.fromJson(Map<String, Object?> json) =>
      _$AdminMemberJoinRequestFromJson(json);
}
