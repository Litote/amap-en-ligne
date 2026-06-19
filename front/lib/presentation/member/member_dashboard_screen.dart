import 'package:amap_en_ligne/presentation/member/volunteer_dashboard_section.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:flutter/material.dart';

/// Member dashboard: thin wrapper around [VolunteerDashboardSection].
///
/// Kept as a standalone widget for backward compatibility with existing
/// tests and direct usages; multi-role users go through `MixedDashboardScreen`.
class MemberDashboardScreen extends StatelessWidget {
  const MemberDashboardScreen({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: 'Tableau de bord',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [VolunteerDashboardSection(tenantId: tenantId)],
      ),
    );
  }
}
