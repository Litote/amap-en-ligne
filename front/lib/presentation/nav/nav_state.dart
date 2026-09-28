import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/presentation/nav/nav_item.dart';
import 'package:flutter/foundation.dart';

/// Immutable UI state for the navigation menu.
///
/// Not Freezed because [NavItem] contains [VoidCallback] which is not
/// equatable — hand-rolled [copyWith] is sufficient here.
@immutable
class NavState {
  const NavState({
    this.isOpen = false,
    this.role = UserRole.memberNoRole,
    this.memberRoles = const {},
    this.items = const [],
  });

  final bool isOpen;
  final UserRole role;

  /// All AMAP-context [Role] values the user holds (VOLUNTEER / COORDINATOR /
  /// ADMIN). Derived from JWT claims via [resolveMemberRoles].
  /// Empty for OWNER and PRODUCER sessions.
  final Set<Role> memberRoles;
  final List<NavItem> items;

  NavState copyWith({
    bool? isOpen,
    UserRole? role,
    Set<Role>? memberRoles,
    List<NavItem>? items,
  }) => NavState(
    isOpen: isOpen ?? this.isOpen,
    role: role ?? this.role,
    memberRoles: memberRoles ?? this.memberRoles,
    items: items ?? this.items,
  );
}
