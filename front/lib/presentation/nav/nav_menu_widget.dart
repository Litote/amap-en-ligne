import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/nav/nav_item.dart';
import 'package:amap_en_ligne/presentation/nav/nav_menu_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Full-screen overlay navigation menu for mobile/tablet layouts.
///
/// Displays the authenticated user's name, the role-appropriate item list,
/// and a close button. Navigates via go_router when a route item is tapped.
class NavMenuWidget extends StatelessWidget {
  const NavMenuWidget({super.key, required this.items, this.onClose});

  final List<NavItem> items;

  /// Called when the user requests to close the menu. Null in desktop layout
  /// where the sidebar is always visible and cannot be closed.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NavMenuHeader(onClose: onClose),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  for (final item in items)
                    NavMenuItemTile(
                      item: item,
                      onTap: () {
                        onClose?.call();
                        if (item.onTap != null) {
                          item.onTap!();
                        } else if (item.route != null) {
                          context.go(item.route!);
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavMenuHeader extends StatelessWidget {
  const _NavMenuHeader({required this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthViewState>(
      builder: (context, authState) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.account_circle, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(authState),
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _roleSubtitle(authState),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  tooltip: 'Fermer le menu',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        );
      },
    );
  }
}

String _displayName(AuthViewState authState) {
  final firstName = authState.firstName?.trim() ?? '';
  final lastName = authState.lastName?.trim() ?? '';
  final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
  return fullName.isNotEmpty ? fullName : (authState.producerId ?? '');
}

/// Returns the subtitle shown under the user's name in the menu header.
///
/// Multi-role: "Rôles : BÉNÉVOLE · COORDINATEUR" (ascending privilege order).
/// Single MemberRole or platform role: the role's display name.
String _roleSubtitle(AuthViewState authState) {
  final memberRoles = authState.memberRoles;
  if (memberRoles.length > 1) {
    final labels = memberRoles.map(_memberRoleLabel).join(' · ');
    return 'Rôles : $labels';
  }
  if (memberRoles.length == 1) {
    return _memberRoleLabel(memberRoles.first);
  }
  return _platformRoleLabel(authState.role);
}

String _memberRoleLabel(Role role) => switch (role) {
  Role.volunteer => 'BÉNÉVOLE',
  Role.coordinator => 'COORDINATEUR',
  Role.admin => 'ADMIN',
  Role.owner || Role.producer => '',
};

String _platformRoleLabel(UserRole role) => switch (role) {
  UserRole.volunteer => 'Bénévole',
  UserRole.coordinator => 'Coordinateur',
  UserRole.memberNoRole => 'Membre',
  UserRole.admin => 'Administrateur',
  UserRole.owner => 'Propriétaire',
  UserRole.producer => 'Producteur',
};
