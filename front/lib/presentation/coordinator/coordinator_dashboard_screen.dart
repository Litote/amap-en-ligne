import 'package:amap_en_ligne/presentation/coordinator/coordinator_dashboard_section.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_status_banner.dart';
import 'package:flutter/material.dart';

/// Coordinator dashboard: thin wrapper around [CoordinatorDashboardSection].
///
/// Kept as a standalone route for backward compatibility; multi-role users
/// are routed through `MixedDashboardScreen` at `/dashboard`.
class CoordinatorDashboardScreen extends StatelessWidget {
  const CoordinatorDashboardScreen({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: 'Coordinateur',
      actions: const [SyncButton()],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SyncStatusBanner(),
          CoordinatorDashboardSection(tenantId: tenantId),
        ],
      ),
    );
  }
}
