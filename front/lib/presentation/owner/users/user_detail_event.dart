import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_detail_event.freezed.dart';

@freezed
sealed class UserDetailEvent with _$UserDetailEvent {
  /// Load the detail for the user identified by [userId].
  /// For Owner users, [userId] is the [Owner.ownerId].
  /// For Member-only users, [userId] is the [Member.memberId] of any row.
  const factory UserDetailEvent.loaded(String userId) = UserDetailLoadRequested;

  /// Change the AMAP roles for one membership.
  const factory UserDetailEvent.membershipRolesChanged({
    required String memberId,
    required String organizationId,
    required Set<Role> newRoles,
  }) = UserDetailMembershipRolesChanged;
}
