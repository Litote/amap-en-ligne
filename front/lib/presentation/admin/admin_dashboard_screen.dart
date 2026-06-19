import 'package:amap_en_ligne/presentation/admin/admin_dashboard_section.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_status_banner.dart';
import 'package:flutter/material.dart';

/// Hub screen for the admin role.
///
/// Mirrors `documentation/feature/fr/ui/admin/screen-admin-01-home.md`. Now a
/// thin wrapper around [AdminDashboardSection] so the same content can be
/// stacked under a multi-role dashboard.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({required this.organizationId, super.key});

  final String organizationId;

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: 'Admin · Tableau de bord',
      actions: const [SyncButton()],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SyncStatusBanner(),
          AdminDashboardSection(organizationId: organizationId),
        ],
      ),
    );
  }
}
