import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/presentation/nav/nav_item.dart';
import 'package:flutter/material.dart';

/// Builds [NavItem]s for a set of AMAP-context [Role]s, merging sections when
/// the user holds multiple roles.
///
/// Roles are iterated in the order: VOLUNTEER → COORDINATOR → ADMIN.
/// When [roles] is empty, only the common items are returned.
List<NavItem> buildNavItems(Set<Role> roles, VoidCallback onLogout) {
  final ordered = [
    if (roles.contains(Role.volunteer)) Role.volunteer,
    if (roles.contains(Role.coordinator)) Role.coordinator,
    if (roles.contains(Role.admin)) Role.admin,
  ];

  if (ordered.isEmpty) return _commonItems(onLogout);

  final isMulti = ordered.length > 1;
  final result = <NavItem>[];
  final seen = <String>{}; // deduplication key: "label|route"

  for (final role in ordered) {
    if (isMulti) {
      result.add(NavItem.sectionHeader(_memberRoleLabel(role)));
    }
    for (final item in _itemsForRole(role)) {
      final key = '${item.label}|${item.route}';
      if (seen.add(key)) result.add(item);
    }
  }

  result.add(const NavItem.separator());
  result.addAll(_commonItems(onLogout));
  return result;
}

/// Builds [NavItem]s for the given [UserRole].
///
/// For AMAP-context roles (volunteer, coordinator, admin), delegates to
/// [buildNavItems] so the item lists stay in sync. Platform roles (owner,
/// producer, memberNoRole) use their own dedicated item lists.
List<NavItem> buildNavItemsForRole(UserRole role, VoidCallback onLogout) {
  return switch (role) {
    UserRole.volunteer => buildNavItems({Role.volunteer}, onLogout),
    UserRole.coordinator => buildNavItems({Role.coordinator}, onLogout),
    UserRole.admin => buildNavItems({Role.admin}, onLogout),
    UserRole.memberNoRole => [
      ..._memberNoRoleItems,
      const NavItem.separator(),
      ..._commonItems(onLogout),
    ],
    UserRole.owner => [
      ..._ownerItems,
      const NavItem.separator(),
      ..._commonItems(onLogout),
    ],
    UserRole.producer => [
      ..._producerItems,
      const NavItem.separator(),
      ..._commonItems(onLogout),
    ],
  };
}

String _memberRoleLabel(Role role) => switch (role) {
  Role.volunteer => '— Bénévole —',
  Role.coordinator => '— Coordinateur —',
  Role.admin => '— Admin —',
  Role.owner || Role.producer => '',
};

List<NavItem> _itemsForRole(Role role) => switch (role) {
  Role.volunteer => _volunteerRoleItems,
  Role.coordinator => _coordinatorRoleItems,
  Role.admin => _adminRoleItems,
  Role.owner || Role.producer => const [],
};

// --- Role item lists (spec: screen-common-01-menu.md) ---

const _volunteerRoleItems = [
  NavItem(label: 'Accueil', icon: Icons.home, route: '/dashboard'),
  NavItem(label: 'Mes contrats', icon: Icons.description, route: '/contracts'),
  NavItem(label: 'Mon historique', icon: Icons.history, route: '/history'),
  NavItem(
    label: 'Planning des livraisons',
    icon: Icons.calendar_month,
    route: '/planning',
  ),
  NavItem(
    label: 'Échange de paniers',
    icon: Icons.swap_horiz,
    route: '/basket-exchange',
  ),
];

const _coordinatorRoleItems = [
  NavItem(label: 'Accueil', icon: Icons.home, route: '/dashboard'),
  NavItem(label: 'Mes contrats', icon: Icons.description, route: '/contracts'),
  NavItem(label: 'Mon historique', icon: Icons.history, route: '/history'),
  NavItem(
    label: 'Planning des livraisons',
    icon: Icons.calendar_month,
    route: '/planning',
  ),
  NavItem(
    label: 'Gestion des livraisons',
    icon: Icons.schedule,
    route: '/coordinator/time-slots',
  ),
  NavItem(
    label: "Feuilles d'émargement",
    icon: Icons.assignment,
    route: '/coordinator/attendance',
  ),
  NavItem(
    label: 'Gestion des contrats',
    icon: Icons.edit_document,
    route: '/coordinator/contracts',
  ),
  NavItem(
    label: 'Contrats par Amapien',
    icon: Icons.assignment_ind,
    route: '/coordinator/member-contracts',
  ),
  NavItem(
    label: 'Échange de paniers',
    icon: Icons.swap_horiz,
    route: '/basket-exchange',
  ),
];

const _adminRoleItems = [
  NavItem(label: 'Accueil', icon: Icons.home, route: '/dashboard'),
  NavItem(
    label: 'Utilisateurs',
    icon: Icons.manage_accounts,
    route: '/members',
  ),
  NavItem(
    label: 'Producteurs',
    icon: Icons.agriculture,
    route: '/admin/producers',
  ),
  NavItem(
    label: 'Templates de livraison',
    icon: Icons.event_repeat,
    route: '/admin/delivery-templates',
  ),
  NavItem(
    label: "Demandes d'adhésion",
    icon: Icons.person_add,
    route: '/admin/membership-requests',
  ),
  NavItem(
    label: 'Échange de paniers',
    icon: Icons.swap_horiz,
    route: '/basket-exchange',
  ),
];

// --- Platform-role item lists ---

const _memberNoRoleItems = [
  NavItem(label: 'Accueil', icon: Icons.home, route: '/dashboard'),
];

const _ownerItems = [
  NavItem(label: 'Accueil', icon: Icons.home, route: '/owner/dashboard'),
  NavItem(
    label: "Demandes d'organisation",
    icon: Icons.domain_add,
    route: '/admin/organization-requests',
  ),
  NavItem(
    label: 'Demandes producteurs',
    icon: Icons.agriculture,
    route: '/admin/producer-requests',
  ),
  NavItem(
    label: 'Utilisateurs',
    icon: Icons.manage_accounts,
    route: '/owner/users',
  ),
  NavItem(
    label: 'Nouvel Administrateur',
    icon: Icons.person_add,
    route: '/owner/invite-administrator',
  ),
];

const _producerItems = [
  NavItem(
    label: 'Accueil producteur',
    icon: Icons.home,
    route: '/product-types',
  ),
];

// --- Common items (always shown, every role) ---

List<NavItem> _commonItems(VoidCallback onLogout) => [
  const NavItem(label: 'Préférences', icon: Icons.tune, route: '/preferences'),
  NavItem(label: 'Se déconnecter', icon: Icons.logout, onTap: onLogout),
];
