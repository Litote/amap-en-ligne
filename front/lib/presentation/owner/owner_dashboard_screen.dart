import 'package:amap_en_ligne/data/repositories/organization_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_request_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Home screen for the OWNER role.
///
/// Mirrors `documentation/feature/fr/ui/owner/screen-owner-01-home.md`:
/// pending-requests CTA, instance-level stats, and an organisation-requests
/// entry — all routed to `/admin/organization-requests` (AMAP tab active).
class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  static const String _ownerHomeTitle =
      'Administrateur Instance · Tableau de bord';
  static const String _organizationRequestsRoute =
      '/admin/organization-requests';
  static const String _producerRequestsRoute = '/admin/producer-requests';
  static const String _userManagementRoute = '/owner/users';
  static const String _inviteOwnerRoute = '/owner/invite-administrator';

  @override
  Widget build(BuildContext context) {
    final repository = context.read<OrganizationRequestRepository>();
    final producerRequestRepository = context.read<ProducerRequestRepository>();

    return ConnectedScaffold(
      title: _ownerHomeTitle,
      actions: const [SyncButton()],
      body: StreamBuilder<List<AdminOrganizationRequest>>(
        stream: repository.watch(),
        initialData: const <AdminOrganizationRequest>[],
        builder: (context, orgSnapshot) {
          return StreamBuilder<List<AdminProducerRequest>>(
            stream: producerRequestRepository.watch(),
            initialData: const <AdminProducerRequest>[],
            builder: (context, producerSnapshot) {
              final organizationRequests =
                  orgSnapshot.data ?? const <AdminOrganizationRequest>[];
              final producerRequests =
                  producerSnapshot.data ?? const <AdminProducerRequest>[];
              final stats = _InstanceStats.from(
                organizationRequests: organizationRequests,
                producerRequests: producerRequests,
              );
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SyncStatusBanner(),
                  _PendingRequestsCard(
                    pendingCount: stats.pendingCount,
                    onTap: () => context.go(_organizationRequestsRoute),
                  ),
                  const SizedBox(height: 16),
                  _InstanceStatsCard(stats: stats),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  _OrganizationRequestsEntry(
                    onTap: () => context.go(_organizationRequestsRoute),
                  ),
                  const SizedBox(height: 8),
                  _ProducerRequestsEntry(
                    onTap: () => context.go(_producerRequestsRoute),
                  ),
                  const SizedBox(height: 8),
                  _UserManagementEntry(
                    onTap: () => context.go(_userManagementRoute),
                  ),
                  const SizedBox(height: 8),
                  _NewAdministratorEntry(
                    onTap: () => context.go(_inviteOwnerRoute),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _PendingRequestsCard extends StatelessWidget {
  const _PendingRequestsCard({required this.pendingCount, required this.onTap});

  final int pendingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Demandes en attente', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '$pendingCount ${pendingCount == 1 ? 'demande' : 'demandes'} '
              'à traiter (AMAP + Producteurs)',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: onTap,
                child: const Text('VOIR LES DEMANDES'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstanceStatsCard extends StatelessWidget {
  const _InstanceStatsCard({required this.stats});

  final _InstanceStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vue instance', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _StatLine(
              label: 'Organisations actives',
              // No instance-wide org listing yet — approximate with the number
              // of approved org requests, which create an active organization.
              value: '${stats.activeOrganizations}',
            ),
            const SizedBox(height: 6),
            _StatLine(
              label: 'Demandes ce mois',
              value: '${stats.requestsThisMonth}',
            ),
            const SizedBox(height: 6),
            _StatLine(
              label: 'Demandes refusées ce mois',
              value: '${stats.rejectedThisMonth}',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OrganizationRequestsEntry extends StatelessWidget {
  const _OrganizationRequestsEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.domain_add),
        title: const Text("Demandes d'organisation"),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _UserManagementEntry extends StatelessWidget {
  const _UserManagementEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.manage_accounts),
        title: const Text('Gestion des utilisateurs'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ProducerRequestsEntry extends StatelessWidget {
  const _ProducerRequestsEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.agriculture),
        title: const Text('Demandes producteurs'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _NewAdministratorEntry extends StatelessWidget {
  const _NewAdministratorEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('new_administrator_entry'),
      child: ListTile(
        leading: const Icon(Icons.person_add),
        title: const Text('Nouvel Administrateur'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _InstanceStats {
  const _InstanceStats({
    required this.pendingCount,
    required this.activeOrganizations,
    required this.requestsThisMonth,
    required this.rejectedThisMonth,
  });

  factory _InstanceStats.from({
    required List<AdminOrganizationRequest> organizationRequests,
    required List<AdminProducerRequest> producerRequests,
  }) {
    final now = DateTime.now();
    final orgStats = _tallyOrganizationRequests(organizationRequests, now);
    final producerStats = _tallyProducerRequests(producerRequests, now);
    return _InstanceStats(
      pendingCount: orgStats.pending + producerStats.pending,
      activeOrganizations: orgStats.approved,
      requestsThisMonth: orgStats.monthTotal + producerStats.monthTotal,
      rejectedThisMonth: orgStats.monthRejected + producerStats.monthRejected,
    );
  }

  static bool _isThisMonth(String submittedAt, DateTime now) {
    final dt = DateTime.tryParse(submittedAt);
    return dt != null && dt.year == now.year && dt.month == now.month;
  }

  static ({int pending, int approved, int monthTotal, int monthRejected})
  _tallyOrganizationRequests(
    List<AdminOrganizationRequest> requests,
    DateTime now,
  ) {
    var pending = 0;
    var approved = 0;
    var monthTotal = 0;
    var monthRejected = 0;
    for (final request in requests) {
      switch (request.status) {
        case OrganizationRequestStatus.pendingValidation:
          pending += 1;
        case OrganizationRequestStatus.approved:
          approved += 1;
        case OrganizationRequestStatus.rejected:
          break;
      }
      if (_isThisMonth(request.submittedAt, now)) {
        monthTotal += 1;
        if (request.status == OrganizationRequestStatus.rejected) {
          monthRejected += 1;
        }
      }
    }
    return (
      pending: pending,
      approved: approved,
      monthTotal: monthTotal,
      monthRejected: monthRejected,
    );
  }

  static ({int pending, int monthTotal, int monthRejected})
  _tallyProducerRequests(List<AdminProducerRequest> requests, DateTime now) {
    var pending = 0;
    var monthTotal = 0;
    var monthRejected = 0;
    for (final request in requests) {
      if (request.status == ProducerRequestStatus.pendingValidation) {
        pending += 1;
      }
      if (_isThisMonth(request.submittedAt, now)) {
        monthTotal += 1;
        if (request.status == ProducerRequestStatus.rejected) {
          monthRejected += 1;
        }
      }
    }
    return (
      pending: pending,
      monthTotal: monthTotal,
      monthRejected: monthRejected,
    );
  }

  final int pendingCount;
  final int activeOrganizations;
  final int requestsThisMonth;
  final int rejectedThisMonth;
}
