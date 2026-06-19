part of 'user_management_bloc.dart';

enum InvitationStatusFilter { active, cancelled }

enum UserStatusFilter { active, suspended }

@freezed
sealed class UserManagementState with _$UserManagementState {
  const factory UserManagementState.initial() = UserManagementInitial;
  const factory UserManagementState.loading() = UserManagementLoading;
  const factory UserManagementState.loaded({
    required List<Member> members,
    @Default(<MemberInvitation>[]) List<MemberInvitation> memberInvitations,
    @Default('') String searchQuery,
    Role? roleFilter,
    @Default(InvitationStatusFilter.active)
    InvitationStatusFilter invitationStatusFilter,
    @Default(UserStatusFilter.active) UserStatusFilter userStatusFilter,
    Member? editingMember,
    @Default(<Role>{}) Set<Role> pendingRoles,
    @Default(false) bool saving,
    @Default(false) bool showingInviteForm,
    @Default('') String inviteFirstName,
    @Default('') String inviteLastName,
    @Default('') String inviteEmail,
    @Default(<Role>{}) Set<Role> inviteRoles,
    @Default(false) bool inviting,
    @Default(<String>{}) Set<String> resendingInvitationIds,
    @Default(<String>{}) Set<String> deletingInvitationIds,
    @Default(false) bool resendingAllPending,
    String? inviteError,
    @Default(false) bool inviteSuccess,
    String? feedbackMessage,
    @Default(false) bool feedbackIsError,
  }) = UserManagementLoaded;
  const factory UserManagementState.error(String message) = UserManagementError;
}
