import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/presentation/admin/admin_dashboard_section.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_dashboard_section.dart';
import 'package:amap_en_ligne/presentation/dashboard/basket_exchange_dashboard_card.dart';
import 'package:amap_en_ligne/presentation/member/volunteer_dashboard_section.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Unified dashboard composed from one section per AMAP-context role held by
/// the user.
///
/// Sections are stacked in privilege order — VOLUNTEER → COORDINATOR → ADMIN —
/// the same order the navigation menu uses (`nav_items_builder.dart`). A
/// section header is rendered above each section only when the user holds more
/// than one AMAP role; a single-role user sees the section without a header.
///
/// Platform roles (OWNER, PRODUCER) land on their dedicated routes and do not
/// reach this screen.
class MixedDashboardScreen extends StatelessWidget {
  const MixedDashboardScreen({required this.tenantId, super.key});

  final String tenantId;

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: 'Tableau de bord',
      actions: const [SyncButton()],
      body: BlocSelector<AuthBloc, AuthViewState, Set<Role>>(
        selector: (state) => state.memberRoles,
        builder: (context, memberRoles) {
          final ordered = _orderedRoles(memberRoles);
          final multi = ordered.length > 1;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SyncStatusBanner(),
              BasketExchangeDashboardCard(tenantId: tenantId),
              for (final role in ordered) ...[
                if (multi) ...[
                  _RoleHeader(label: memberRoleLabel(role)),
                  const SizedBox(height: 8),
                ],
                _sectionFor(role, tenantId: tenantId),
                const SizedBox(height: 24),
              ],
            ],
          );
        },
      ),
    );
  }

  static List<Role> _orderedRoles(Set<Role> roles) => [
    if (roles.contains(Role.volunteer)) Role.volunteer,
    if (roles.contains(Role.coordinator)) Role.coordinator,
    if (roles.contains(Role.admin)) Role.admin,
  ];

  static Widget _sectionFor(Role role, {required String tenantId}) =>
      switch (role) {
        Role.volunteer => VolunteerDashboardSection(tenantId: tenantId),
        Role.coordinator => CoordinatorDashboardSection(tenantId: tenantId),
        Role.admin => AdminDashboardSection(organizationId: tenantId),
        Role.owner || Role.producer => const SizedBox.shrink(),
      };
}

/// Label used as a section header in the multi-role dashboard. Mirrors the
/// labels in the navigation menu (`nav_items_builder.dart`).
String memberRoleLabel(Role role) => switch (role) {
  Role.volunteer => '— Bénévole —',
  Role.coordinator => '— Coordinateur —',
  Role.admin => '— Admin —',
  Role.owner || Role.producer => '',
};

class _RoleHeader extends StatelessWidget {
  const _RoleHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
