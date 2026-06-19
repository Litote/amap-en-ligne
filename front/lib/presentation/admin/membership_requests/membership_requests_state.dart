import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'membership_requests_state.freezed.dart';

@freezed
sealed class MembershipRequestsState with _$MembershipRequestsState {
  const factory MembershipRequestsState.initial() = MembershipRequestsInitial;

  const factory MembershipRequestsState.loading() = MembershipRequestsLoading;

  const factory MembershipRequestsState.loaded({
    required List<AdminMemberJoinRequest> requests,
    MemberJoinRequestStatus? statusFilter,
    @Default(false) bool actionInProgress,
    String? actionError,
  }) = MembershipRequestsLoaded;

  const factory MembershipRequestsState.error(String message) =
      MembershipRequestsError;
}
