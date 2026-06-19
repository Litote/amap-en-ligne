import 'package:freezed_annotation/freezed_annotation.dart';

part 'member_join_request.freezed.dart';
part 'member_join_request.g.dart';

@freezed
abstract class MemberJoinRequest with _$MemberJoinRequest {
  const factory MemberJoinRequest({
    @JsonKey(name: 'organization_id') required String organizationId,
    required String email,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
  }) = _MemberJoinRequest;

  factory MemberJoinRequest.fromJson(Map<String, Object?> json) =>
      _$MemberJoinRequestFromJson(json);
}

@freezed
abstract class MemberJoinRequestResponse with _$MemberJoinRequestResponse {
  const factory MemberJoinRequestResponse({
    @JsonKey(name: 'request_id') required String requestId,
    required String status,
  }) = _MemberJoinRequestResponse;

  factory MemberJoinRequestResponse.fromJson(Map<String, Object?> json) =>
      _$MemberJoinRequestResponseFromJson(json);
}

/// Conflict field returned by `POST /v1/public/member-join-requests` on 409.
enum MemberJoinConflictField {
  email,
  emailMember,
  emailOwner,
  emailProducer,
  unknown,
}

class MemberJoinConflictException implements Exception {
  const MemberJoinConflictException(this.field);

  final MemberJoinConflictField field;
}
