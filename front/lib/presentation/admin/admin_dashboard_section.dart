import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Admin section of the unified dashboard.
///
/// Renders Accès rapides + Alertes + Synthèse — the body of the historic
/// `AdminDashboardScreen`, without its own scaffold. Composed by
/// `MixedDashboardScreen` and reused as the body of the standalone screen.
class AdminDashboardSection extends StatelessWidget {
  const AdminDashboardSection({required this.organizationId, super.key});

  final String organizationId;

  @override
  Widget build(BuildContext context) {
    final memberRepository = context.read<MemberRepository>();
    final organizationRepository = context.read<OrganizationRepository>();

    return StreamBuilder<List<Member>>(
      stream: memberRepository.watch(organizationId),
      initialData: const <Member>[],
      builder: (context, memberSnapshot) {
        return StreamBuilder<Organization?>(
          stream: organizationRepository.watch(organizationId),
          builder: (context, orgSnapshot) {
            final stats = _DashboardStats.from(
              members: memberSnapshot.data ?? const <Member>[],
              organization: orgSnapshot.data,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel(label: 'Accès rapides'),
                const SizedBox(height: 8),
                const _DashboardTile(
                  icon: Icons.people,
                  label: 'Utilisateurs',
                  route: '/members',
                ),
                const _DashboardTile(
                  icon: Icons.agriculture,
                  label: 'Producteurs',
                  route: '/admin/producers',
                ),
                const _DashboardTile(
                  icon: Icons.event_repeat,
                  label: 'Templates de livraison',
                  route: '/admin/delivery-templates',
                ),
                const _DashboardTile(
                  icon: Icons.tune,
                  label: 'Préférences',
                  route: '/preferences',
                ),
                const _DashboardTile(
                  icon: Icons.person_add,
                  label: "Demandes d'adhésion",
                  route: '/admin/membership-requests',
                ),
                const SizedBox(height: 24),
                _AlertsCard(stats: stats),
                const SizedBox(height: 16),
                _SyntheseCard(stats: stats),
              ],
            );
          },
        );
      },
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(route),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.stats});

  final _DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = <Widget>[];
    if (stats.suspendedProducers > 0) {
      lines.add(
        _BulletLine(
          text:
              '${stats.suspendedProducers} '
              'producteur${stats.suspendedProducers == 1 ? '' : 's'} '
              'suspendu${stats.suspendedProducers == 1 ? '' : 's'}',
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alertes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (lines.isEmpty)
              Text('Aucune alerte en cours.', style: theme.textTheme.bodyMedium)
            else
              ...lines,
          ],
        ),
      ),
    );
  }
}

class _SyntheseCard extends StatelessWidget {
  const _SyntheseCard({required this.stats});

  final _DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Synthèse', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _StatLine(label: 'Membres actifs', value: '${stats.activeMembers}'),
            const SizedBox(height: 6),
            _StatLine(label: 'Coordinateurs', value: '${stats.coordinators}'),
            const SizedBox(height: 6),
            _StatLine(
              label: 'Producteurs actifs',
              value: '${stats.activeProducers}',
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

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _DashboardStats {
  const _DashboardStats({
    required this.activeMembers,
    required this.coordinators,
    required this.activeProducers,
    required this.suspendedProducers,
  });

  factory _DashboardStats.from({
    required List<Member> members,
    required Organization? organization,
  }) {
    final activeMembers = members.where((m) => m.activeStatus).toList();
    final coordinators = activeMembers
        .where((m) => m.roles.contains(Role.coordinator))
        .length;
    final producers = organization?.producers ?? const <OrganizationProducer>[];
    final activeProducers = producers
        .where((p) => p.status == OrganizationProducerStatus.active)
        .length;
    final suspendedProducers = producers
        .where((p) => p.status == OrganizationProducerStatus.suspended)
        .length;
    return _DashboardStats(
      activeMembers: activeMembers.length,
      coordinators: coordinators,
      activeProducers: activeProducers,
      suspendedProducers: suspendedProducers,
    );
  }

  final int activeMembers;
  final int coordinators;
  final int activeProducers;
  final int suspendedProducers;
}
