import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.started() = AuthStarted;

  const factory AuthEvent.sessionChanged(AuthState session) =
      AuthSessionChanged;

  const factory AuthEvent.organizationIdChanged(String? organizationId) =
      AuthOrganizationIdChanged;

  const factory AuthEvent.memberNameUpdated(
    String? firstName,
    String? lastName,
  ) = AuthMemberNameUpdated;

  const factory AuthEvent.memberRolesUpdated(Set<Role> roles) =
      AuthMemberRolesUpdated;

  const factory AuthEvent.loginSubmitted({
    required String email,
    required String password,
    required bool rememberMe,
  }) = AuthLoginSubmitted;

  const factory AuthEvent.logoutRequested() = AuthLogoutRequested;
}
