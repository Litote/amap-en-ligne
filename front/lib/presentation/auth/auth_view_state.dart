import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_view_state.freezed.dart';

/// UI-facing auth state. The session-level state lives in
/// `domain/auth/auth_state.dart` — this one carries the bits the login form
/// needs (submitting indicator, last error) on top of the resolved session.
///
/// `producerId` is the JWT `sub` claim — the user's identity from the auth provider.
///
/// `producerAccountId` is the effective producer account ID resolved from the
/// database (via sync cursors). Only for producers; null for other roles.
///
/// `organizationId` is the effective organization ID resolved from the
/// database (via sync cursors). Only for non-producers (non-owner, non-producer).
@freezed
abstract class AuthViewState with _$AuthViewState {
  const factory AuthViewState({
    @Default(true) bool initializing,
    @Default(false) bool submitting,
    @Default(false) bool logoutRequested,
    String? producerId,
    String? producerAccountId,
    String? organizationId,
    @Default(false) bool isAdmin,
    @Default(UserRole.memberNoRole) UserRole role,
    @Default(<Role>{}) Set<Role> memberRoles,
    AuthError? lastError,
  }) = _AuthViewState;
}
