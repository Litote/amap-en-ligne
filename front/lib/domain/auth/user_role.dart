import 'package:amap_en_ligne/domain/auth/role.dart';

/// Role of the authenticated user within the AMAP network.
///
/// Used to drive role-based navigation menus. Resolution priority follows
/// the order of checks in [UserRoleResolver.resolveRole].
enum UserRole { volunteer, coordinator, memberNoRole, admin, owner, producer }

/// Resolves the highest-priority [UserRole] from a list of raw role strings.
extension UserRoleResolver on List<String> {
  UserRole resolveRole() {
    if (contains('OWNER')) return UserRole.owner;
    if (contains('ADMIN')) return UserRole.admin;
    if (contains('COORDINATOR')) return UserRole.coordinator;
    if (contains('VOLUNTEER')) return UserRole.volunteer;
    if (contains('PRODUCER')) return UserRole.producer;
    return UserRole.memberNoRole;
  }

  /// Returns all AMAP-context [Role] values present in this JWT role string
  /// list, in ascending privilege order (VOLUNTEER → COORDINATOR → ADMIN).
  ///
  /// Non-AMAP strings (OWNER, PRODUCER) are ignored — they have their own
  /// navigation context and are not part of AMAP membership roles.
  Set<Role> resolveMemberRoles() => {
    if (contains('VOLUNTEER')) Role.volunteer,
    if (contains('COORDINATOR')) Role.coordinator,
    if (contains('ADMIN')) Role.admin,
  };
}
