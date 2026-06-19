part of 'user_management_bloc.dart';

@freezed
sealed class UserManagementEvent with _$UserManagementEvent {
  const factory UserManagementEvent.loadRequested() = _LoadRequested;
  const factory UserManagementEvent.searchChanged(String query) =
      _SearchChanged;
  const factory UserManagementEvent.roleFilterChanged(Role? role) =
      _RoleFilterChanged;
  const factory UserManagementEvent.invitationStatusFilterChanged(
    InvitationStatusFilter filter,
  ) = _InvitationStatusFilterChanged;
  const factory UserManagementEvent.userStatusFilterChanged(
    UserStatusFilter filter,
  ) = _UserStatusFilterChanged;
  const factory UserManagementEvent.editRolesRequested(Member member) =
      _EditRolesRequested;
  const factory UserManagementEvent.roleToggled(Role role, bool isChecked) =
      _RoleToggled;
  const factory UserManagementEvent.saveRolesRequested() = _SaveRolesRequested;
  const factory UserManagementEvent.editCancelled() = _EditCancelled;

  // Invite member events
  const factory UserManagementEvent.showInviteForm() = _ShowInviteForm;
  const factory UserManagementEvent.inviteFirstNameChanged(String value) =
      _InviteFirstNameChanged;
  const factory UserManagementEvent.inviteLastNameChanged(String value) =
      _InviteLastNameChanged;
  const factory UserManagementEvent.inviteEmailChanged(String value) =
      _InviteEmailChanged;
  const factory UserManagementEvent.inviteRoleToggled(
    Role role,
    bool isChecked,
  ) = _InviteRoleToggled;
  const factory UserManagementEvent.resendInvitationRequested(
    MemberInvitation invitation,
  ) = _ResendInvitationRequested;
  const factory UserManagementEvent.deleteInvitationRequested(
    MemberInvitation invitation,
  ) = _DeleteInvitationRequested;

  /// Re-sends the connection/invitation email to every still-pending invitation,
  /// optionally overriding the default email subject/body for this send.
  const factory UserManagementEvent.resendAllPendingRequested({
    String? customEmailSubject,
    String? customEmailBody,
  }) = _ResendAllPendingRequested;
  const factory UserManagementEvent.submitInvitation() = _SubmitInvitation;
  const factory UserManagementEvent.dismissInviteForm() = _DismissInviteForm;
  const factory UserManagementEvent.feedbackDismissed() = _FeedbackDismissed;
}
