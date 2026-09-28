import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'membership_requests_event.freezed.dart';

@freezed
sealed class MembershipRequestsEvent with _$MembershipRequestsEvent {
  const factory MembershipRequestsEvent.loadRequested({
    MemberJoinRequestStatus? statusFilter,
  }) = MembershipRequestsLoadRequested;

  const factory MembershipRequestsEvent.approveRequested({
    required AdminMemberJoinRequest request,
  }) = MembershipRequestsApproveRequested;

  const factory MembershipRequestsEvent.rejectRequested({
    required AdminMemberJoinRequest request,
    String? reviewComment,
  }) = MembershipRequestsRejectRequested;
}
